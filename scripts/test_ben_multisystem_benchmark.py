"""Contract-level tests; isolated true-BEN CI is a separate evidence gate."""
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import ben_multisystem_benchmark as bm


FIXTURES = Path(__file__).parent / "fixtures/ben_multisystem_m13.json"
FAKE_CAPS = {"playsSystems": ["21GF", "SAYC", "21GF-GIB"],
             "readsSystems": ["21GF", "SAYC", "21GF-GIB", "BEN:READONLY"],
             "defaults": {"ourSystem": "21GF-GIB"}}


class LocalContractTest(unittest.TestCase):
    def test_all_fixture_seat_context_and_hand_valid(self):
        rows = bm.fixtures_from_json(FIXTURES)
        self.assertGreaterEqual(len(rows), 12)
        self.assertEqual(len(rows), len({f["id"] for f in rows}))

    def test_auction_legality(self):
        self.assertTrue(bm.legal_next("1S--", "2H"))
        self.assertFalse(bm.legal_next("1S--", "1H"))
        self.assertTrue(bm.legal_next("", "PASS"))
        self.assertTrue(bm.legal_next("", "1NT"))
        self.assertFalse(bm.legal_next("1N--", "1N"))
        self.assertTrue(bm.legal_next("1S2C", "X"))
        self.assertFalse(bm.legal_next("1S--", "X"))
        self.assertFalse(bm.legal_next("", "8N"))

    def test_unsafe_loopback_url_rejected(self):
        for url in ["https://127.0.0.1:8085", "http://example.com:8085",
                    "http://localhost:8085", "http://127.0.0.1:8085/bid",
                    "http://127.0.0.1:8085/?hand=SECRET",
                    "http://token:pass@127.0.0.1:8085"]:
            with self.subTest(url=url), self.assertRaises(bm.BenchmarkError):
                bm.loopback_url(url)
        self.assertEqual("http://127.0.0.1:8085/", bm.loopback_url("http://127.0.0.1:8085/"))

    def test_bad_hand_or_turn_fails(self):
        f = dict(bm.fixtures_from_json(FIXTURES)[0])
        f["hand"] = "AKQ.AJ.234.2"
        with self.assertRaises(bm.BenchmarkError):
            bm.validate_fixture(f)
        f = dict(bm.fixtures_from_json(FIXTURES)[4])
        f["seat"] = "W"
        with self.assertRaises(bm.BenchmarkError):
            bm.validate_fixture(f)

    def test_parse_context_rejects_invalid(self):
        self.assertEqual(["1S", "--", "2H", "--"], bm.parse_context("1S--2H--"))
        with self.assertRaises(bm.BenchmarkError):
            bm.parse_context("1S-P-2H")

    def test_nearest_rank_latency_percentiles(self):
        self.assertEqual(5.0, bm.percentile([1,2,3,4,5], 99))
        self.assertEqual(3.0, bm.percentile([1,2,3,4,5], 50))
        self.assertIsNone(bm.percentile([], 50))

    def test_system_propagation_and_redacted_report(self):
        calls=[]
        def fake_get(_url, route, query=None, **kwargs):
            if route == "/": return FAKE_CAPS
            calls.append((route, query["ourSystem"], query["theirSystem"]))
            return {"bid":"2H"}
        f=dict(bm.fixtures_from_json(FIXTURES)[4])
        with patch.object(bm, "get_json", side_effect=fake_get):
            a=bm.query_bid("http://127.0.0.1:8085",f,"SAYC",timeout=20)
        self.assertEqual([("/bid", "SAYC", "21GF")], calls)
        self.assertNotIn("hand", a)
        self.assertEqual("2H",a["bid"])

    def test_real_bid_invalid_response_must_fail(self):
        f=dict(bm.fixtures_from_json(FIXTURES)[4])
        for value in ("INVALID", "1C", None):
            with self.subTest(value=value), patch.object(bm, "get_json", return_value={"bid":value}):
                with self.assertRaises(bm.BenchmarkError):
                    bm.query_bid("http://127.0.0.1:8085", f, "SAYC", timeout=20)

    def test_forcing_violation_is_not_marked_pass(self):
        f=next(f for f in bm.fixtures_from_json(FIXTURES) if f["id"]=="2over1_responder")
        def fake_get(_url, route, query=None, **kwargs):
            return FAKE_CAPS if route=="/" else {"bid":"PASS"}
        with patch.object(bm, "get_json", side_effect=fake_get), patch.object(bm, "reject_unknown", return_value=True):
            result=bm.run_m13("http://127.0.0.1:8085", [f], timeout=20)
        self.assertEqual("SEMANTIC_REVIEW_REQUIRED", result["status"])
        self.assertTrue(result["forcingViolations"])
        self.assertFalse(result["expertReviewed"])

    def test_missing_system_not_silent_fallback(self):
        with patch.object(bm, "get_json", return_value={"playsSystems":["SAYC"],
                "readsSystems":["SAYC"],"defaults":{}}):
            with self.assertRaises(bm.BenchmarkError):
                bm.verify_capabilities("http://127.0.0.1:8085")

    def test_cpu_times_read_actual_linux_process_without_hand(self):
        clock = bm.read_cpu_seconds(os.getpid())
        self.assertIsNotNone(clock)
        self.assertGreaterEqual(clock, 0.)
        self.assertIsNone(bm.read_cpu_seconds(999999999))

    def test_m14_mock_only_does_not_prove_vps(self):
        rows=bm.fixtures_from_json(FIXTURES)
        with patch.object(bm, "get_json", side_effect=lambda u,r,q=None,**kw: FAKE_CAPS if r=="/" else {"bid":"PASS"}),patch.object(bm,"read_rss",return_value=12000):
            result=bm.run_m14("http://127.0.0.1:8085",rows,pid=12345)
        self.assertEqual("NOT_TESTED_ON_TARGET_HOST",result["targetVps4gb"])
        self.assertEqual(8,result["stats"]["singleWorker_c4"]["requests"])

    def test_instrumentation_never_hides_bid_url_errors(self):
        with patch.object(bm,"get_json", side_effect=bm.BenchmarkError("BEN request failed (URL and hand intentionally redacted)")):
            with self.assertRaises(bm.BenchmarkError) as error:
                bm.query_bid("http://127.0.0.1:8085",bm.fixtures_from_json(FIXTURES)[0],"SAYC",timeout=20)
        self.assertNotIn("AQ976",str(error.exception))


if __name__ == "__main__":
    unittest.main()
