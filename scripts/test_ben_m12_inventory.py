"""M1.2 audit tests: synthetic artifacts, no real model or external services."""
import tempfile
import unittest
from pathlib import Path

import ben_m12_inventory as audit


CONF = """
[21GF]
bidder = models/TF2models/21.keras
info = models/TF2models/21-info.keras
cc = BBA/CC/21.bbsa
plays = True

[SAYC]
bidder = models/TF2models/sayc.keras
info = models/TF2models/sayc-info.keras
cc = BBA/CC/sayc.bbsa
plays = True

[BEN:READONLY]
bidder = models/TF2models/ro.keras
cc = BBA/CC/ro.bbsa
plays = False
"""


class InventoryTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.write("src/config/systems.conf", CONF)
        self.write("src/config/default_api.conf", "[models]\nname = test\n")
        self.write("requirements.txt", "tensorflow==2.21.0\n")
        self.write("bin/dds3-linux/dds3/_dds3.so", "test-native-only")
        for name in ("21", "21-info", "sayc", "sayc-info", "ro"):
            self.write(f"models/TF2models/{name}.keras", f"synthetic {name}")
        for name in ("21", "sayc", "ro"):
            self.write(f"BBA/CC/{name}.bbsa", f"synthetic convention {name}")

    def write(self, path: str, value: str):
        full = self.root / path
        full.parent.mkdir(parents=True, exist_ok=True)
        full.write_text(value, encoding="utf-8")

    def test_pinned_inventory_includes_all_declared_artifacts(self):
        result = audit.inspect(self.root, audit.EXPECTED_BEN_SHA)
        self.assertEqual("PASS", result["status"])
        self.assertEqual({"SAYC", "21GF"}, set(result["targetProfiles"]))
        self.assertIn("BEN:READONLY", result["registeredSystems"])
        self.assertIn("models/TF2models/ro.keras", result["artifacts"])
        self.assertEqual(64, len(result["artifacts"]["models/TF2models/ro.keras"]["sha256"]))
        self.assertFalse(result["license"]["redistributionApproved"])
        self.assertEqual("NOT_RUN", result["realBidAcceptance"])
        self.assertEqual("NOT_RUN", result["runtimeCapabilities"])

    def test_mismatched_upstream_commit_is_rejected(self):
        with self.assertRaises(audit.InventoryError):
            audit.inspect(self.root, "deadbeef")

    def test_missing_sayc_weights_fails(self):
        (self.root / "models/TF2models/sayc.keras").unlink()
        with self.assertRaises(audit.InventoryError):
            audit.inspect(self.root, audit.EXPECTED_BEN_SHA)

    def test_read_only_model_declared_is_also_required(self):
        (self.root / "models/TF2models/ro.keras").unlink()
        with self.assertRaises(audit.InventoryError):
            audit.inspect(self.root, audit.EXPECTED_BEN_SHA)

    def test_path_traversal_is_rejected(self):
        self.write("src/config/systems.conf",
                   CONF.replace("models/TF2models/21.keras", "../../outside.keras"))
        with self.assertRaises(audit.InventoryError):
            audit.inspect(self.root, audit.EXPECTED_BEN_SHA)

    def test_wrong_plays_is_rejected(self):
        self.write("src/config/systems.conf",
                   CONF.replace("[SAYC]\nbidder =", "[SAYC]\nplays = False\nbidder =")
                   .replace("cc = BBA/CC/sayc.bbsa\nplays = True",
                            "cc = BBA/CC/sayc.bbsa"))
        with self.assertRaises(audit.InventoryError):
            audit.inspect(self.root, audit.EXPECTED_BEN_SHA)

    def test_digest_changes_when_weight_changes(self):
        first = audit.inspect(self.root, audit.EXPECTED_BEN_SHA)
        self.write("models/TF2models/sayc.keras", "modified model bytes")
        second = audit.inspect(self.root, audit.EXPECTED_BEN_SHA)
        self.assertNotEqual(
            first["artifacts"]["models/TF2models/sayc.keras"]["sha256"],
            second["artifacts"]["models/TF2models/sayc.keras"]["sha256"],
        )

    def test_invalid_config_fails_closed(self):
        self.write("src/config/systems.conf", "[bad\n")
        with self.assertRaises(audit.InventoryError):
            audit.inspect(self.root, audit.EXPECTED_BEN_SHA)


if __name__ == "__main__":
    unittest.main()
