#!/usr/bin/env python3
"""M1.2 reproducible, read-only BEN model inventory for isolated CI.

Only trusted local artifacts are hashed. No weights or binaries are copied to
Bridge Academy; reports contain paths, sizes and digests but no card hands.
An inventory is NOT an approval of third-party redistribution rights.
"""
from __future__ import annotations

import argparse
import configparser
import hashlib
import json
import os
import sys
from pathlib import Path

EXPECTED_BEN_SHA = "ad8608af6e6bfe095863023f344f3cb2cbafec3d"
TARGETS = ("21GF", "SAYC")
MAX_FILE_BYTES = 1024 * 1024 * 1024
EVIDENCE_SCOPE = "M1_2_FILE_PROVENANCE_ONLY_NOT_LICENSE_OR_AI_QUALITY"


class InventoryError(Exception):
    """Safe error text: do not include private paths or data."""


def _safe_location(root: Path, relative: str) -> Path:
    """A declared upstream artifact must resolve to a file within BEN root."""
    if not relative or os.path.isabs(relative) or ".." in Path(relative).parts:
        raise InventoryError("invalid artifact path")
    item = root / relative
    if item.is_symlink() or not item.resolve().is_relative_to(root.resolve()):
        raise InventoryError("artifact escaped BEN root")
    if not item.is_file():
        raise InventoryError("declared artifact missing")
    if item.stat().st_size > MAX_FILE_BYTES:
        raise InventoryError("artifact too large to audit")
    return item


def digest_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def inspect(root: Path, commit: str) -> dict:
    if commit != EXPECTED_BEN_SHA:
        raise InventoryError("BEN commit does not match the reviewed M1.2 candidate")
    root = root.resolve()
    if not root.is_dir():
        raise InventoryError("BEN checkout missing")
    config_path = _safe_location(root, "src/config/systems.conf")
    config = configparser.ConfigParser(interpolation=None, strict=True)
    try:
        config.read_string(config_path.read_text(encoding="utf-8"))
    except (configparser.Error, UnicodeError):
        raise InventoryError("invalid BEN system configuration") from None
    if not config.sections():
        raise InventoryError("no BEN systems")
    files: dict[str, dict] = {}
    targets: dict[str, dict] = {}
    load_paths: dict[str, dict] = {}
    for section in config.sections():
        if section.upper() not in TARGETS:
            continue
        if not config.getboolean(section, "plays", fallback=False):
            raise InventoryError("required BEN target not playable")
        targets[section.upper()] = {}
        for key in ("bidder", "info", "cc"):
            if not config.has_option(section, key):
                raise InventoryError("required model field missing")
            relative = config.get(section, key)
            file = _safe_location(root, relative)
            files[relative] = {"sha256": digest_file(file), "bytes": file.stat().st_size}
            targets[section.upper()][key] = relative
    if set(targets) != set(TARGETS):
        raise InventoryError("missing required BEN system")

    # BEN Systems.load loads the readable opponent-model catalog on startup,
    # not just the two target models. Hash every declared artifact to make
    # model provenance auditable (does NOT mean training quality is verified).
    for section in config.sections():
        load_paths[section] = {}
        for key in ("bidder", "info", "cc"):
            if not config.has_option(section, key):
                continue
            relative = config.get(section, key)
            file = _safe_location(root, relative)
            if relative not in files:
                files[relative] = {"sha256": digest_file(file), "bytes": file.stat().st_size}
            load_paths[section][key] = relative
    # Other native inference dependencies (and the default API configuration)
    # are also pinned to the same checkout and hashed for provenance.
    extra_paths = [
        "requirements.txt", "src/config/default_api.conf",
        "bin/dds3-linux/dds3/_dds3.so",
    ]
    for relative in extra_paths:
        file = _safe_location(root, relative)
        files[relative] = {"sha256": digest_file(file), "bytes": file.stat().st_size}

    return {
        "status": "PASS",
        "scope": EVIDENCE_SCOPE,
        "upstream": "https://github.com/lorserker/ben",
        "revision": commit,
        "targetProfiles": targets,
        "registeredSystems": load_paths,
        "artifacts": dict(sorted(files.items())),
        "license": {
            "benSource": "GPL-3.0 (upstream LICENSE; redistribution evaluation pending)",
            "modelWeights": "UNREVIEWED_NOT_APPROVED_FOR_REDISTRIBUTION",
            "bbaEpbotBinary": "UNREVIEWED_NOT_APPROVED_FOR_REDISTRIBUTION",
            "ddsNative": "UNREVIEWED_NOT_APPROVED_FOR_REDISTRIBUTION",
            "redistributionApproved": False,
        },
        "runtimeCapabilities": "NOT_RUN",
        "realBidAcceptance": "NOT_RUN",
        "precision": "NOT_SUPPORTED_BY_THIS_INVENTORY",
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--ben-root", type=Path, required=True)
    p.add_argument("--commit", default=EXPECTED_BEN_SHA)
    p.add_argument("--out", type=Path)
    args = p.parse_args(argv)
    try:
        result = inspect(args.ben_root, args.commit)
    except (InventoryError, OSError, ValueError) as exc:
        result = {"status": "FAIL", "scope": EVIDENCE_SCOPE,
                  "error": str(exc) if isinstance(exc, InventoryError) else "inventory failed",
                  "runtimeCapabilities": "NOT_RUN", "realBidAcceptance": "NOT_RUN"}
    encoded = json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True)
    if args.out:
        try:
            args.out.write_text(encoded + "\n", encoding="utf-8")
        except OSError:
            print("Unable to save inventory report", file=sys.stderr)
            return 1
    print(json.dumps({k: v for k, v in result.items() if k != "artifacts" and k != "registeredSystems"},
                     ensure_ascii=False, sort_keys=True))
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
