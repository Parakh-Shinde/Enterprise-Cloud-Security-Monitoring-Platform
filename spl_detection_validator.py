#!/usr/bin/env python3
"""Perform lightweight quality checks on the project's production SPL rules."""

from __future__ import annotations

import re
import sys
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent
DETECTION_DIRECTORY = REPOSITORY_ROOT / "detections"
EXPECTED_IDS = [f"DET-{number:03d}" for number in range(1, 11)]

REQUIRED_PATTERNS = {
    "base index": re.compile(r"(?m)^\s*index\s*="),
    "relative lookback": re.compile(r"\bearliest\s*=\s*-[A-Za-z0-9]+"),
    "detection name": re.compile(r"\bdetection\s*=\s*\"[^\"]+\""),
    "severity": re.compile(r"\bseverity\s*="),
    "MITRE technique": re.compile(
        r"\bmitre_technique\s*=\s*\"T\d{4}(?:\.\d{3})?\""
    ),
    "final table": re.compile(r"(?m)^\s*\|\s*table\b"),
}


def validate_detection(detection_id: str) -> list[str]:
    """Return validation errors for one expected detection."""

    matching_files = sorted(DETECTION_DIRECTORY.glob(f"{detection_id}-*.spl"))
    if len(matching_files) != 1:
        return [
            f"expected exactly one {detection_id}-*.spl file, "
            f"found {len(matching_files)}"
        ]

    path = matching_files[0]
    content = path.read_text(encoding="utf-8")
    errors: list[str] = []

    if not content.strip():
        return ["file is empty"]

    embedded_id = re.compile(
        rf'\bdetection_id\s*=\s*"{re.escape(detection_id)}"'
    )
    if not embedded_id.search(content):
        errors.append("embedded detection_id does not match the filename")

    for requirement, pattern in REQUIRED_PATTERNS.items():
        if not pattern.search(content):
            errors.append(f"missing {requirement}")

    if re.search(r"(?im)^\s*\|\s*makeresults\b", content):
        errors.append("contains synthetic makeresults command")

    return errors


def main() -> int:
    if not DETECTION_DIRECTORY.is_dir():
        print(f"[FAIL] Detection directory not found: {DETECTION_DIRECTORY}")
        return 1

    total_files = list(DETECTION_DIRECTORY.glob("DET-*.spl"))
    failed = False

    print("SPL Detection Quality Check")
    print("=" * 60)

    for detection_id in EXPECTED_IDS:
        errors = validate_detection(detection_id)
        if errors:
            failed = True
            print(f"[FAIL] {detection_id}")
            for error in errors:
                print(f"       - {error}")
        else:
            print(f"[PASS] {detection_id}")

    if len(total_files) != len(EXPECTED_IDS):
        failed = True
        print(
            f"[FAIL] Expected {len(EXPECTED_IDS)} detection files, "
            f"found {len(total_files)}"
        )

    print("=" * 60)
    if failed:
        print("Detection validation failed.")
        return 1

    print(f"All {len(EXPECTED_IDS)} SPL detections passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
