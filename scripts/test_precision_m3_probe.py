"""M3: policy tests run without downloading proprietary EPBot binaries."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import precision_m3_probe as p

FIXTURES = Path(__file__).parent / "fixtures/precision_m3_cases.json"


class PrecisionContractTest(unittest.TestCase):
    def test_research_cases_are_only_reference_candidates(self):
        cases = p.load_cases(FIXTURES)
        self.assertGreaterEqual(len(cases), 8)
        self.assertTrue(any(c["expectStrongClub"] for c in cases))
        self.assertTrue(any(not c["expectStrongClub"] for c in cases))
        self.assertTrue(all(p.parse_hand(c["hand"]) >= 17
                            for c in cases if c["expectStrongClub"]))

    def test_bad_hand_refused(self):
        for value in ["AKQ.KQ.AJ.KQ", "AKQ3.KQ4.AJ3.KQQ", "AXQ3.KQ4.AJ3.KQ7"]:
            with self.subTest(value=value), self.assertRaises(p.ResearchError):
                p.parse_hand(value)

    def test_card_parse_pin_detects_meckwell_nt_disagreement(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            path=root/p.PRECISION_CC
            path.parent.mkdir(parents=True)
            path.write_text("System type = 3\n"
                            "1NT opening range 12-14 = 0\n"
                            "1NT opening range 13-15 = 1\n"
                            "1NT opening range 14-16 = 0\n"
                            "1NT opening range 15-17 = 0\n", encoding="utf-8")
            result=p.summarize_candidate(root)
            self.assertEqual(result["systemType"], 3)
            self.assertEqual(result["oneNtCard"],"13-15")
            self.assertEqual(result["referenceMeckwellLite20260105"],"13-16")
            self.assertFalse(result["cardMatchesReference"])
            self.assertFalse(result["licenseApproved"])
            self.assertFalse(result["playableBENPrecision"])

    def test_wrong_native_system_type_fails_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/p.PRECISION_CC
            path.parent.mkdir(parents=True)
            path.write_text("System type = 1\n1NT opening range 13-15 = 1\n")
            with self.assertRaises(p.ResearchError):
                p.summarize_candidate(Path(temp))

    def test_forged_model_revision_is_rejected(self):
        with patch("subprocess.check_output", return_value="bad_sha\n"):
            with self.assertRaises(p.ResearchError):
                p.check_ben_source(Path("/tmp/upstream"))

    def test_audit_never_claims_release_or_production(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            cc=root/p.PRECISION_CC
            cc.parent.mkdir(parents=True)
            cc.write_text("System type = 3\n"
                          "1NT opening range 12-14 = 0\n"
                          "1NT opening range 13-15 = 1\n"
                          "1NT opening range 14-16 = 0\n"
                          "1NT opening range 15-17 = 0\n")
            with patch.object(p,"check_ben_source"):
                import argparse
                result=p.execute(argparse.Namespace(
                    ben_root=root, fixtures=FIXTURES, live=False))
            self.assertFalse(result["nativeRan"])
            self.assertFalse(result["releaseApproved"])
            self.assertEqual(result["status"],"RESEARCH_ONLY")
            self.assertNotIn("proposals", json.dumps(result))
            self.assertNotIn("AKQ3.KQ4",json.dumps(result))


if __name__ == "__main__":
    unittest.main()
