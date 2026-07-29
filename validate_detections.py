#!/usr/bin/env python3
"""Validate the structure and metadata of the repository's SPL detections."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable


EXPECTED_IDS = {f"DET-{number:03d}" for number in range(1, 11)}
ALLOWED_INDEXES = {"cloudtrail", "linux", "waf", "web"}

FILENAME_PATTERN = re.compile(r"^(DET-\d{3})-[a-z0-9]+(?:-[a-z0-9]+)*\.spl$")
INDEX_PATTERN = re.compile(r"(?m)^\s*index\s*=\s*([A-Za-z0-9_-]+)")
MITRE_PATTERN = re.compile(r'mitre_technique\s*=\s*"(T\d{4}(?:\.\d{3})?)"')
TABLE_PATTERN = re.compile(r"(?im)^\s*\|\s*table\s+([^\n]+)")


@dataclass(frozen=True)
class ValidationResult:
    """Validation status for one SPL detection."""

    path: str
    detection_id: str
    index: str | None
    mitre_technique: str | None
    passed: bool
    errors: tuple[str, ...]


def _balanced_delimiters(content: str) -> str | None:
    """Return an error when unquoted (), [] or {} delimiters are unbalanced."""

    pairs = {")": "(", "]": "[", "}": "{"}
    opening = set(pairs.values())
    stack: list[tuple[str, int]] = []
    in_quote = False
    escaped = False

    for position, character in enumerate(content, start=1):
        if escaped:
            escaped = False
            continue
        if character == "\\":
            escaped = True
            continue
        if character == '"':
            in_quote = not in_quote
            continue
        if in_quote:
            continue
        if character in opening:
            stack.append((character, position))
        elif character in pairs:
            if not stack or stack[-1][0] != pairs[character]:
                return f"unexpected '{character}' at character {position}"
            stack.pop()

    if in_quote:
        return "unterminated double-quoted string"
    if stack:
        character, position = stack[-1]
        return f"unclosed '{character}' from character {position}"
    return None


def _match_group(pattern: re.Pattern[str], content: str) -> str | None:
    match = pattern.search(content)
    return match.group(1) if match else None


def validate_file(path: Path) -> ValidationResult:
    """Validate one SPL file without executing it."""

    content = path.read_text(encoding="utf-8")
    filename_match = FILENAME_PATTERN.fullmatch(path.name)
    filename_id = filename_match.group(1) if filename_match else "UNKNOWN"
    index = _match_group(INDEX_PATTERN, content)
    mitre_technique = _match_group(MITRE_PATTERN, content)
    errors: list[str] = []

    if not filename_match:
        errors.append("filename must follow DET-###-descriptive-name.spl")
    if not content.strip():
        errors.append("file is empty")
    if index is None:
        errors.append("base search must declare an index")
    elif index not in ALLOWED_INDEXES:
        errors.append(f"index '{index}' is not in the approved index set")
    if not re.search(r"\bearliest\s*=\s*-[A-Za-z0-9]+", content):
        errors.append("base search must define a relative earliest lookback")
    if filename_id != "UNKNOWN" and not re.search(
        rf'detection_id\s*=\s*"{re.escape(filename_id)}"', content
    ):
        errors.append("embedded detection_id does not match the filename")
    if not re.search(r'detection\s*=\s*"[^"]+"', content):
        errors.append("detection name is missing")
    if not re.search(r"\bseverity\s*=", content):
        errors.append("severity assignment is missing")
    if not re.search(r'"(?:LOW|MEDIUM|HIGH|CRITICAL)"', content):
        errors.append("severity must use LOW, MEDIUM, HIGH or CRITICAL")
    if mitre_technique is None:
        errors.append("MITRE ATT&CK technique must use T#### or T####.### format")
    if re.search(r"(?im)^\s*\|\s*makeresults\b", content):
        errors.append("synthetic makeresults searches are not production detections")

    table_match = TABLE_PATTERN.search(content)
    if not table_match:
        errors.append("final table output is missing")
    else:
        output_fields = set(table_match.group(1).split())
        required_fields = {"detection_id", "detection", "severity"}
        missing_fields = sorted(required_fields - output_fields)
        if missing_fields:
            errors.append(
                "final table is missing required fields: " + ", ".join(missing_fields)
            )

    delimiter_error = _balanced_delimiters(content)
    if delimiter_error:
        errors.append(f"delimiter check failed: {delimiter_error}")

    return ValidationResult(
        path=path.as_posix(),
        detection_id=filename_id,
        index=index,
        mitre_technique=mitre_technique,
        passed=not errors,
        errors=tuple(errors),
    )


def validate_directory(directory: Path) -> tuple[list[ValidationResult], list[str]]:
    """Validate every SPL detection and repository-level ID requirements."""

    files = sorted(directory.glob("DET-*.spl"))
    results = [validate_file(path) for path in files]
    repository_errors: list[str] = []

    discovered_ids = [
        result.detection_id for result in results if result.detection_id != "UNKNOWN"
    ]
    discovered_set = set(discovered_ids)

    if len(files) != len(EXPECTED_IDS):
        repository_errors.append(
            f"expected {len(EXPECTED_IDS)} SPL files, found {len(files)}"
        )
    if len(discovered_ids) != len(discovered_set):
        repository_errors.append("duplicate detection IDs found")

    missing = sorted(EXPECTED_IDS - discovered_set)
    unexpected = sorted(discovered_set - EXPECTED_IDS)
    if missing:
        repository_errors.append("missing detection IDs: " + ", ".join(missing))
    if unexpected:
        repository_errors.append("unexpected detection IDs: " + ", ".join(unexpected))

    return results, repository_errors


def _print_results(
    results: Iterable[ValidationResult], repository_errors: Iterable[str]
) -> None:
    print("SPL Detection Quality Report")
    print("=" * 72)
    for result in results:
        status = "PASS" if result.passed else "FAIL"
        print(
            f"[{status}] {result.detection_id:<7} "
            f"index={result.index or 'missing':<10} "
            f"mitre={result.mitre_technique or 'missing':<9} "
            f"{result.path}"
        )
        for error in result.errors:
            print(f"       - {error}")

    for error in repository_errors:
        print(f"[FAIL] repository: {error}")


def _write_json_report(
    output_path: Path,
    results: list[ValidationResult],
    repository_errors: list[str],
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "summary": {
            "total": len(results),
            "passed": sum(result.passed for result in results),
            "failed": sum(not result.passed for result in results),
            "repository_errors": len(repository_errors),
        },
        "repository_errors": repository_errors,
        "detections": [asdict(result) for result in results],
    }
    output_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate SPL detection structure and embedded metadata."
    )
    parser.add_argument(
        "--directory",
        type=Path,
        default=Path("detections"),
        help="directory containing DET-*.spl files (default: detections)",
    )
    parser.add_argument(
        "--json-output",
        type=Path,
        help="optional path for a machine-readable JSON report",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.directory.is_dir():
        print(f"Detection directory not found: {args.directory}", file=sys.stderr)
        return 2

    results, repository_errors = validate_directory(args.directory)
    _print_results(results, repository_errors)
    if args.json_output:
        _write_json_report(args.json_output, results, repository_errors)

    failed = repository_errors or any(not result.passed for result in results)
    print("=" * 72)
    print("FAILED" if failed else f"PASSED: {len(results)} detections validated")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
