#!/usr/bin/env python3
"""M3 research-only Precision/EPBot probe; NEVER deploy or redistribute BBA.

The probe checks upstream provenance, Precision CC type and documented variation.
--live loads the existing BEN checkout's native EPBot transiently on CI; the
private / non-permissively-licensed binaries and input hands are never copied to
this repository or printed in logs. It does NOT certify expert bidding quality.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

PINNED_BEN = "ad8608af6e6bfe095863023f344f3cb2cbafec3d"
PRECISION_CC = "BBA/CC/Meckwell.bbsa"
SAYC_CC = "BBA/CC/BEN-SAYC.bbsa"
SCHEMA = "M3_PRECISION_ISOLATED_RESEARCH_V1"
RANKS = "AKQJT98765432"
HCP = {"A": 4, "K": 3, "Q": 2, "J": 1}
VALID_BIDS = re.compile(r"^(PASS|P|--|X|XX|[1-7](?:C|D|H|S|N|NT))$", re.I)


class ResearchError(Exception):
    pass


def read_cc(path: Path) -> tuple[int, dict[str, int], str]:
    if not path.is_file() or path.is_symlink():
        raise ResearchError("Missing / unsafe upstream convention card")
    raw = path.read_bytes()
    rules = {}
    for line in raw.decode("utf-8-sig").splitlines():
        if not line.strip():
            continue
        if " = " not in line:
            raise ResearchError("Malformed upstream convention card")
        name, value = line.split(" = ", 1)
        if not value.strip().isdigit() or name in rules:
            raise ResearchError("Malformed or duplicate upstream rule")
        rules[name] = int(value)
    typ = rules.pop("System type", None)
    if not isinstance(typ, int):
        raise ResearchError("Missing upstream system type")
    return typ, rules, hashlib.sha256(raw).hexdigest()


def summarize_candidate(ben_root: Path) -> dict:
    typ, rules, digest = read_cc(ben_root / PRECISION_CC)
    if typ != 3:
        raise ResearchError("Upstream Meckwell card is not Precision type 3")
    nt = {key: rules.get(key) for key in (
        "1NT opening range 12-14", "1NT opening range 13-15",
        "1NT opening range 14-16", "1NT opening range 15-17",
    )}
    if list(nt.values()).count(1) != 1:
        raise ResearchError("Upstream 1NT range missing or ambiguous")
    if nt["1NT opening range 13-15"] != 1:
        raise ResearchError("Unexpected Meckwell NT card; review before using")
    return {
        "systemType": typ,
        "cardPath": PRECISION_CC,
        "cardSha256": digest,
        "oneNtCard": "13-15",
        "referenceMeckwellLite20260105": "13-16",
        "cardMatchesReference": False,
        "playableBENPrecision": False,
        "candidateOnly": True,
        "licenseApproved": False,
    }


def check_ben_source(ben_root: Path) -> None:
    import subprocess
    try:
        actual = subprocess.check_output(
            ["git", "-C", str(ben_root), "rev-parse", "HEAD"],
            timeout=10, stderr=subprocess.DEVNULL, text=True).strip()
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        raise ResearchError("BEN source pin not verifiable") from None
    if actual != PINNED_BEN:
        raise ResearchError("BEN upstream SHA does not match reviewed pin")


def parse_hand(hand: str) -> int:
    parts = hand.upper().split(".")
    if len(parts) != 4 or sum(len(s) for s in parts) != 13:
        raise ResearchError("Fixture must have exactly thirteen cards")
    if any(len(set(s)) != len(s) or any(c not in RANKS for c in s) for s in parts):
        raise ResearchError("Invalid fixture hand")
    return sum(HCP.get(c, 0) for part in parts for c in part)


def load_cases(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list) or len(data) < 6:
        raise ResearchError("Require at least six candidate cases")
    ids = set()
    for case in data:
        if not isinstance(case, dict) or sorted(case) != [
            "expectStrongClub", "hand", "id",
        ]:
            raise ResearchError("Case schema mismatch")
        name = case["id"]
        if not isinstance(name, str) or not re.fullmatch(r"[a-z0-9_]{3,40}", name):
            raise ResearchError("Case ID invalid")
        if name in ids:
            raise ResearchError("Case ID duplicate")
        ids.add(name)
        points = parse_hand(case["hand"])
        if not isinstance(case["expectStrongClub"], bool):
            raise ResearchError("Invalid golden expectation flag")
        if case["expectStrongClub"] and points < 17:
            raise ResearchError("Strong club reference requires at least 17 HCP")
    return data


def probe_native(ben_root: Path, cases: list[dict]) -> dict:
    # The native library is loaded ONLY by explicit --live in a disposable CI.
    # No modifications to BEN source or BBA .bbsa are made.
    sys.path.insert(0, str((ben_root / "src").resolve()))
    sys.path.insert(0, str(ben_root.resolve()))
    from bba.BBA import BBABotBid  # noqa: PLC0415 — isolated optional import

    precision = str((ben_root / PRECISION_CC).resolve())
    sayc = str((ben_root / SAYC_CC).resolve())
    results = []
    for case in cases:
        bot = BBABotBid(
            precision, sayc, 0, case["hand"], (False, False), 0, False, False)
        result = bot.bid([])
        proposal = result.bid
        if not isinstance(proposal, str) or not VALID_BIDS.fullmatch(proposal):
            raise ResearchError("Native EPBot returned an invalid opening")
        # A mismatch is a research finding, not silent correction to 1C.
        results.append({
            "id": case["id"], "hcp": parse_hand(case["hand"]),
            "opening": proposal,
            "strongClubCandidate": case["expectStrongClub"],
            "strongClubObserved": proposal.upper() == "1C",
        })
    violations = [
        r["id"] for r in results
        if r["strongClubCandidate"] and not r["strongClubObserved"]
    ]
    return {
        "nativeRan": True, "cases": len(results),
        "proposals": results,
        "strongClubDiscrepancies": violations,
        "expertReviewed": False,
        "qualityProven": False,
    }


def execute(args: argparse.Namespace) -> dict:
    root = args.ben_root.resolve()
    check_ben_source(root)
    card = summarize_candidate(root)
    cases = load_cases(args.fixtures)
    output = {
        "schema": SCHEMA, "benCommit": PINNED_BEN,
        "status": "RESEARCH_ONLY",
        "candidate": card, "fixtureCount": len(cases),
        "nativeRan": False, "releaseApproved": False,
        "notes": "BBA license is unspecified; CI research only; no model deployment",
    }
    if args.live:
        output["experiment"] = probe_native(root, cases)
        output["nativeRan"] = True
        output["status"] = "OBSERVED_NOT_RELEASE_APPROVED"
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ben-root", type=Path, required=True)
    parser.add_argument("--fixtures", type=Path,
                        default=Path("scripts/fixtures/precision_m3_cases.json"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--live", action="store_true")
    args = parser.parse_args()
    try:
        result = execute(args)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n",
                               encoding="utf-8")
        print(json.dumps({k: v for k, v in result.items()
                          if k != "experiment"}, sort_keys=True))
        if "experiment" in result:
            print("NATIVE_BBA_PRECISION_CASES:",
                  result["experiment"]["cases"],
                  "STRONG_CLUB_DISCREPANCIES:",
                  len(result["experiment"]["strongClubDiscrepancies"]))
        return 0
    except (ResearchError, OSError, ValueError, ImportError):
        # Never print potential upstream hand URL, binary path, or traceback.
        print("PRECISION_RESEARCH_FAILED (redacted)", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
