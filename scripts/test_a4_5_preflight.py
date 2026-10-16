import json
import tempfile
import unittest
from pathlib import Path
from a4_5_preflight import assess, main

BASE = {
    "environment": "staging",
    "public_origin": "https://staging.example.invalid",
    "tls_termination": True,
    "gateway_bind": "127.0.0.1",
    "ben_bind": "127.0.0.1",
    "raw_decision_enabled": False,
    "browser_origins": ["https://staging.example.invalid"],
    "checkpoint_encrypted": True,
    "checkpoint_key_external": True,
    "anonymous_access": True,
    "single_instance": True,
    "persistent_rate_limits": False,
    "external_identity": False,
    "distributed_idempotency": False,
    "license_approved": False,
    "capacity_evidence": False,
    "rollback_tested": False,
}


class PreflightTests(unittest.TestCase):
    def test_staging_static_manifest(self):
        self.assertEqual(assess(dict(BASE), "staging"), [])

    def test_production_not_accidentally_approved(self):
        prod = dict(BASE, environment="production")
        self.assertTrue(assess(prod, "production"))

    def test_never_accept_unsafe_gateway_bind(self):
        for addr in ("0.0.0.0", "::", "localhost", "8.8.8.8", ""):
            with self.subTest(addr=addr):
                cfg = dict(BASE, gateway_bind=addr)
                self.assertTrue(assess(cfg, "staging"))

    def test_block_raw_decision_and_wildcard_cors(self):
        for extra in (
            {"raw_decision_enabled": True},
            {"browser_origins": ["*"]},
            {"browser_origins": ["http://staging.example.invalid"]},
            {"browser_origins": ["https://evil.example.invalid"]},
        ):
            self.assertTrue(assess(dict(BASE, **extra), "staging"))

    def test_block_secret_keys_and_unrecognized_fields(self):
        self.assertTrue(assess(dict(BASE, api_key="do-not-store"), "staging"))
        self.assertTrue(assess(dict(BASE, invented_flag=True), "staging"))

    def test_require_checkpoint_and_https(self):
        for extra in (
            {"checkpoint_encrypted": False},
            {"checkpoint_key_external": False},
            {"public_origin": "http://staging.example.invalid"},
            {"public_origin": "https://user:pwd@staging.example.invalid"},
            {"public_origin": "https://staging.example.invalid/path"},
            {"tls_termination": False},
        ):
            self.assertTrue(assess(dict(BASE, **extra), "staging"))

    def test_command_exit_codes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            path.write_text(json.dumps(BASE), encoding="utf-8")
            self.assertEqual(main(["--config", str(path), "--profile", "staging"]), 0)
            self.assertEqual(main(["--config", str(path), "--profile", "production"]), 1)
            path.write_text("{bad", encoding="utf-8")
            self.assertEqual(main(["--config", str(path), "--profile", "staging"]), 2)


if __name__ == "__main__":
    unittest.main()
