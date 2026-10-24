#!/usr/bin/env python3
"""M1: read-only BEN multi-system capability audit (never sends any hand).

This is a capability *contract* probe. PASS does not prove bid quality,
installed model weights, licensing, or the live game's system compatibility.

Examples:
  python scripts/ben_system_probe.py --systems-conf third_party_ben/src/config/systems.conf
  python scripts/ben_system_probe.py --url http://127.0.0.1:8085/
  python scripts/ben_system_probe.py --systems-conf ... --url http://127.0.0.1:8085/
"""
from __future__ import annotations

import argparse
import configparser
import ipaddress
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import (
    HTTPRedirectHandler, ProxyHandler, Request, build_opener,
)

DEFAULT_REQUIRED = ("21GF", "SAYC")
MAX_RESPONSE_BYTES = 16384


class ProbeError(ValueError):
    """Safe-to-print capability/format error (never contains a hand)."""


def _names(value: object, key: str) -> set[str]:
    if not isinstance(value, list) or any(
        not isinstance(s, str) or not s or s != s.strip() for s in value
    ):
        raise ProbeError(f"{key} must be an array of nonempty names")
    names = [s.upper() for s in value]
    if len(names) != len(set(names)):
        raise ProbeError(f"{key} includes duplicate names")
    return set(names)


def inspect_systems_conf(path: Path, *, check_artifacts: bool = False) -> dict:
    """Inspect *declarations*, not whether networks run or use the conventions."""
    if not path.is_file():
        raise ProbeError("systems.conf not found")
    config = configparser.ConfigParser(interpolation=None)
    try:
        with path.open(encoding="utf-8") as stream:
            config.read_file(stream)
    except (OSError, UnicodeError, configparser.Error) as exc:
        raise ProbeError("systems.conf could not be parsed") from exc
    if not config.sections():
        raise ProbeError("systems.conf contains no registered systems")
    plays, reads = set(), set()
    errors: list[str] = []
    base = path.resolve().parent.parent.parent  # BEN root: src/config/systems.conf
    for section in config.sections():
        name = section.upper()
        if name in reads:
            errors.append(f"duplicate system {name}")
            continue
        reads.add(name)
        try:
            playable = config.getboolean(section, "plays", fallback=False)
        except ValueError:
            errors.append(f"{name}: invalid plays flag")
            continue
        if playable:
            plays.add(name)
        required_keys = ("bidder", "cc") + (("info",) if playable else ())
        for key in required_keys:
            if not config.has_option(section, key) or not config.get(section, key).strip():
                errors.append(f"{name}: missing {key} for {'play' if playable else 'read'}")
        if check_artifacts:
            for key in ("bidder", "info", "cc"):
                if not config.has_option(section, key):
                    continue
                location = (base / config.get(section, key)).resolve()
                if not location.is_relative_to(base):
                    errors.append(f"{name}: unsafe {key} path")
                elif not location.is_file():
                    errors.append(f"{name}: missing {key} artifact")
    return {
        "plays": sorted(plays),
        "reads": sorted(reads),
        "errors": sorted(errors),
        "artifactsChecked": check_artifacts,
    }


class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def _loopback_origin(url: str) -> str:
    """Allow only a literal loopback BEN root; no proxy, redirects or secrets."""
    try:
        parsed = urlsplit(url)
        if (parsed.scheme != "http" or not parsed.hostname or
                parsed.username or parsed.password or
                parsed.path not in ("", "/") or parsed.query or parsed.fragment or
                parsed.port is None or not 1 <= parsed.port <= 65535 or
                not ipaddress.ip_address(parsed.hostname).is_loopback):
            raise ProbeError("BEN url must be an HTTP literal-loopback root with port")
    except (ValueError, TypeError) as exc:
        raise ProbeError("BEN url must be an HTTP literal-loopback root with port") from exc
    host = f"[{parsed.hostname}]" if ":" in parsed.hostname else parsed.hostname
    return f"http://{host}:{parsed.port}/"


def probe_runtime(url: str, *, timeout: float = 5.0) -> dict:
    """Calls GET / only; does not send auction, hand, token, or player details."""
    safe_url = _loopback_origin(url)
    opener = build_opener(ProxyHandler({}), _NoRedirect)
    try:
        req = Request(safe_url, headers={"Accept": "application/json", "Cache-Control": "no-store"})
        with opener.open(req, timeout=timeout) as response:
            data = response.read(MAX_RESPONSE_BYTES + 1)
        if len(data) > MAX_RESPONSE_BYTES:
            raise ProbeError("BEN capabilities response too large")
        capabilities = json.loads(data.decode("utf-8"))
    except (HTTPError, URLError, TimeoutError, OSError, UnicodeError,
            json.JSONDecodeError) as exc:
        raise ProbeError("BEN capability endpoint failed or returned invalid JSON") from exc
    if not isinstance(capabilities, dict):
        raise ProbeError("BEN capabilities must be a JSON object")
    plays = _names(capabilities.get("playsSystems"), "playsSystems")
    reads = _names(capabilities.get("readsSystems"), "readsSystems")
    if not plays.issubset(reads):
        raise ProbeError("BEN playsSystems is not a subset of readsSystems")
    defaults = capabilities.get("defaults")
    if not isinstance(defaults, dict):
        raise ProbeError("BEN defaults must be an object")
    if defaults.get("ourSystem") is not None and (
        not isinstance(defaults["ourSystem"], str) or
        defaults["ourSystem"].upper() not in plays
    ):
        raise ProbeError("BEN default ourSystem is not playable")
    return {"plays": sorted(plays), "reads": sorted(reads),
            "defaultOurSystem": defaults.get("ourSystem")}


def assess(
    *,
    static: dict | None = None,
    live: dict | None = None,
    required: tuple[str, ...] = DEFAULT_REQUIRED,
) -> dict:
    """Reports each evidence type separately; does not imply real bidding passed."""
    normalized = {v.upper() for v in required}
    if not normalized:
        raise ProbeError("at least one system is required")
    checks: dict = {}
    successful = True
    for label, evidence in (("static", static), ("live", live)):
        if evidence is None:
            checks[label] = {"status": "NOT_RUN"}
            continue
        missing = sorted(normalized - set(evidence["plays"]))
        errors = evidence.get("errors", [])
        ok = not missing and not errors
        checks[label] = {
            "status": "PASS" if ok else "FAIL",
            "playable": evidence["plays"],
            "missingRequired": missing,
            "errors": errors,
            "precisionPlayable": "PRECISION" in evidence["plays"],
        }
        successful = successful and ok
    if static is None and live is None:
        raise ProbeError("static or live inspection required")
    return {
        "result": "PASS" if successful else "FAIL",
        "scope": "CAPABILITY_DECLARATIONS_ONLY_NOT_MODEL_QUALITY",
        "requiredPlayable": sorted(normalized),
        "checks": checks,
        "realBiddingModelAcceptance": "NOT_RUN",
        "precisionAcceptance": "NOT_RUN",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--systems-conf", type=Path)
    parser.add_argument("--check-artifacts", action="store_true")
    parser.add_argument("--url", help="BEN GET / on a literal loopback origin only")
    parser.add_argument("--require", default="21GF,SAYC",
                        help="comma-separated required playable system names")
    args = parser.parse_args(argv)
    try:
        required = tuple(s.strip().upper() for s in args.require.split(","))
        if any(not s for s in required):
            raise ProbeError("invalid required system name")
        if args.check_artifacts and args.systems_conf is None:
            raise ProbeError("--check-artifacts requires --systems-conf")
        static = inspect_systems_conf(args.systems_conf, check_artifacts=args.check_artifacts) if args.systems_conf else None
        live = probe_runtime(args.url) if args.url else None
        report = assess(static=static, live=live, required=required)
    except ProbeError as exc:
        report = {"result": "FAIL", "scope": "CAPABILITY_DECLARATIONS_ONLY",
                  "error": str(exc), "realBiddingModelAcceptance": "NOT_RUN"}
    print(json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2))
    return 0 if report["result"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
