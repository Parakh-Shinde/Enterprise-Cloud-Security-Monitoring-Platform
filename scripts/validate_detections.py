from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from scripts.validate_detections import validate_directory, validate_file


VALID_SPL = """\
index=linux sourcetype=linux_secure earliest=-15m
| stats count BY host
| eval detection_id="DET-001",
       detection="Test Detection",
       severity="HIGH",
       mitre_technique="T1110"
| table detection_id detection severity host mitre_technique
"""


class DetectionValidationTests(unittest.TestCase):
    def test_repository_detections_pass(self) -> None:
        results, repository_errors = validate_directory(Path("detections"))

        self.assertEqual(repository_errors, [])
        self.assertEqual(len(results), 10)
        self.assertTrue(all(result.passed for result in results))

    def test_embedded_id_must_match_filename(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            path = Path(temporary_directory) / "DET-002-test-rule.spl"
            path.write_text(VALID_SPL, encoding="utf-8")

            result = validate_file(path)

        self.assertFalse(result.passed)
        self.assertIn(
            "embedded detection_id does not match the filename", result.errors
        )

    def test_makeresults_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            path = Path(temporary_directory) / "DET-001-test-rule.spl"
            path.write_text(
                VALID_SPL.replace(
                    "index=linux sourcetype=linux_secure earliest=-15m",
                    "index=linux sourcetype=linux_secure earliest=-15m\n| makeresults",
                ),
                encoding="utf-8",
            )

            result = validate_file(path)

        self.assertFalse(result.passed)
        self.assertIn(
            "synthetic makeresults searches are not production detections",
            result.errors,
        )


if __name__ == "__main__":
    unittest.main()
