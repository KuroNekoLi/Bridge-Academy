"""M1 BEN capability inspector tests: only mock HTTP and synthetic configs.

These tests do not run TensorFlow, BEN weights, or a real bidding decision.
"""
import json
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from unittest.mock import patch

import ben_system_probe as probe


SYSTEMS_CONF = """
[21GF-GIB]
bidder = models/gib.keras
info = models/gib-info.keras
cc = BBA/CC/gib.bbsa
plays = True

[21GF]
bidder = models/21.keras
info = models/21-info.keras
cc = BBA/CC/21.bbsa
plays = True

[SAYC]
bidder = models/sayc.keras
info = models/sayc-info.keras
cc = BBA/CC/sayc.bbsa
plays = True

[BEN:READONLY]
bidder = models/ro.keras
cc = BBA/CC/ro.bbsa
plays = False
"""


class StaticTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / "src" / "config" / "systems.conf"
        self.path.parent.mkdir(parents=True)
        self.path.write_text(SYSTEMS_CONF, encoding="utf-8")

    def test_21gf_and_sayc_playable_not_readonly(self):
        result = probe.inspect_systems_conf(self.path)
        self.assertIn("21GF", result["plays"])
        self.assertIn("SAYC", result["plays"])
        self.assertNotIn("BEN:READONLY", result["plays"])
        self.assertIn("BEN:READONLY", result["reads"])
        self.assertEqual("PASS", probe.assess(static=result)["result"])
        self.assertEqual("NOT_RUN", probe.assess(static=result)["checks"]["live"]["status"])
        self.assertEqual("NOT_RUN", probe.assess(static=result)["realBiddingModelAcceptance"])

    def test_precision_not_falsely_supported(self):
        result = probe.assess(static=probe.inspect_systems_conf(self.path))
        self.assertFalse(result["checks"]["static"]["precisionPlayable"])
        self.assertEqual("NOT_RUN", result["precisionAcceptance"])

    def test_missing_necessary_information_fails(self):
        self.path.write_text(SYSTEMS_CONF.replace("info = models/sayc-info.keras\n", ""),
                             encoding="utf-8")
        result = probe.inspect_systems_conf(self.path)
        self.assertIn("SAYC: missing info for play", result["errors"])
        self.assertEqual("FAIL", probe.assess(static=result)["result"])

    def test_read_only_21gf_fails_required_system(self):
        self.path.write_text(SYSTEMS_CONF.replace(
            "[21GF]\nbidder = models/21.keras\ninfo = models/21-info.keras\ncc = BBA/CC/21.bbsa\nplays = True",
            "[21GF]\nbidder = models/21.keras\ninfo = models/21-info.keras\ncc = BBA/CC/21.bbsa\nplays = False"),
            encoding="utf-8")
        report = probe.assess(static=probe.inspect_systems_conf(self.path))
        self.assertEqual("FAIL", report["result"])
        self.assertIn("21GF", report["checks"]["static"]["missingRequired"])

    def test_artifact_check_is_opt_in_and_fail_closed(self):
        result = probe.inspect_systems_conf(self.path)
        self.assertFalse(result["artifactsChecked"])
        checked = probe.inspect_systems_conf(self.path, check_artifacts=True)
        self.assertTrue(checked["artifactsChecked"])
        self.assertTrue(any("missing bidder artifact" in e for e in checked["errors"]))

    def test_conf_parse_failure_and_no_mode(self):
        with self.assertRaises(probe.ProbeError):
            probe.assess()
        self.path.write_text("[bad\n", encoding="utf-8")
        with self.assertRaises(probe.ProbeError):
            probe.inspect_systems_conf(self.path)


class ApiTest(unittest.TestCase):
    def setUp(self):
        self.payload = {
            "playsSystems": ["21GF-GIB", "21GF", "SAYC"],
            "readsSystems": ["21GF-GIB", "21GF", "SAYC", "BEN:READONLY"],
            "defaults": {"ourSystem": "21GF-GIB"}
        }
        fixture = self

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                fixture.last_path = self.path
                data = json.dumps(fixture.payload).encode()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)

            def log_message(self, *args):
                pass

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.url = f"http://127.0.0.1:{self.server.server_port}/"

    def test_live_capability_only_without_hand(self):
        result = probe.probe_runtime(self.url)
        self.assertEqual("/", self.last_path)
        self.assertIn("SAYC", result["plays"])
        self.assertEqual("PASS", probe.assess(live=result)["result"])
        self.assertEqual("NOT_RUN", probe.assess(live=result)["checks"]["static"]["status"])

    def test_runtime_missing_sayc_is_failure(self):
        self.payload["playsSystems"] = ["21GF"]
        self.payload["readsSystems"] = ["21GF"]
        self.payload["defaults"] = {"ourSystem": "21GF"}
        report = probe.assess(live=probe.probe_runtime(self.url))
        self.assertEqual("FAIL", report["result"])
        self.assertEqual(["SAYC"], report["checks"]["live"]["missingRequired"])

    def test_unknown_default_rejected(self):
        self.payload["defaults"] = {"ourSystem": "BOGUS"}
        with self.assertRaises(probe.ProbeError):
            probe.probe_runtime(self.url)

    def test_non_loopback_and_private_url_material_rejected(self):
        for url in ("https://127.0.0.1:8085/", "http://example.com:8085/",
                    "http://127.0.0.1:8085/?hand=SECRET",
                    "http://user:password@127.0.0.1:8085/",
                    "http://127.0.0.1:8085/bid",
                    "http://127.0.0.1/",
                    "http://localhost:8085/"):
            with self.subTest(url=url), self.assertRaises(probe.ProbeError):
                probe.probe_runtime(url)

    def test_duplicate_or_invalid_systems_rejected(self):
        self.payload["playsSystems"] = ["21GF", "21gf", "SAYC"]
        with self.assertRaises(probe.ProbeError):
            probe.probe_runtime(self.url)

    def test_json_cli_summarizes_and_fails_closed(self):
        with patch("sys.stdout") as output:
            self.assertEqual(0, probe.main(["--url", self.url]))
            self.assertEqual(1, probe.main(["--url", "http://example.com:8085/"]))


if __name__ == "__main__":
    unittest.main()
