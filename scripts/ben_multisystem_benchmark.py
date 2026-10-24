#!/usr/bin/env python3
"""M1.3/1.4 true-BEN /bid verification and reproducible isolated capacity probes.

No synthetic/mock result can be labelled REAL_BEN_PASS. The single seat's hand
goes only to an IP-literal loopback BEN instance; it never enters logs/reports.
Do not use this tool for live competitive deals: fixtures are public/test only.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import math
import os
import re
import statistics
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

REQUIRED = ("21GF", "SAYC")
SUITS = "CDHSN"
CTX_CALL = re.compile(r"--|Db|Rd|[1-7][CDHSN]", re.I)
BID = re.compile(r"^[1-7][CDHSN]$")
RANKS = "23456789TJQKA"
SEATS = "NESW"  # The index sequence is clockwise N -> E -> S -> W.
MAX_BYTES = 32768


class BenchmarkError(RuntimeError):
    """Keep errors free from hand, URI and upstream message."""


def loopback_url(value: str) -> str:
    try:
        u = urllib.parse.urlsplit(value)
        if (u.scheme != "http" or u.username or u.password or
                u.query or u.fragment or u.path not in ("", "/") or
                u.hostname not in ("127.0.0.1", "::1") or
                u.port is None or not 1 <= u.port <= 65535):
            raise BenchmarkError("benchmark requires literal loopback HTTP BEN origin with port")
        return f"http://{u.hostname}:{u.port}/" if ":" not in u.hostname else f"http://[{u.hostname}]:{u.port}/"
    except (ValueError, TypeError) as exc:
        raise BenchmarkError("invalid BEN benchmark endpoint") from exc


def parse_context(ctx: str) -> list[str]:
    if not isinstance(ctx, str):
        raise BenchmarkError("invalid ctx")
    result: list[str] = []
    n = 0
    for m in CTX_CALL.finditer(ctx):
        if m.start() != n:
            raise BenchmarkError("unrecognized auction encoding")
        result.append(m.group())
        n = m.end()
    if n != len(ctx):
        raise BenchmarkError("unrecognized auction encoding")
    return result


def validate_hand(value: str) -> None:
    if not isinstance(value, str):
        raise BenchmarkError("invalid fixture hand")
    parts = value.upper().split(".")
    if len(parts) != 4:
        raise BenchmarkError("fixture hand must have four suits")
    if sum(map(len, parts)) != 13:
        raise BenchmarkError("fixture hand must contain thirteen cards")
    if any(len(set(p)) != len(p) or any(c not in RANKS for c in p) for p in parts):
        raise BenchmarkError("fixture hand contains illegal/duplicate ranks")


def bid_rank(code: str) -> int:
    return (int(code[0]) - 1) * 5 + SUITS.index(code[1])


def legal_next(ctx: str, proposal: str) -> bool:
    """Independent auction-legality precheck; Bridge Core remains authoritative."""
    calls = parse_context(ctx)
    bid = proposal.upper().replace("NT", "N").strip()
    if bid in ("PASS", "P", "--", "PA"):
        return True
    previous = -1
    doubled = False
    redoubled = False
    bid_seat: int | None = None
    next_seat = 0
    for call in calls:
        normalized = call.upper()
        if BID.fullmatch(normalized):
            rank = bid_rank(normalized)
            if rank <= previous:
                raise BenchmarkError("invalid fixture auction order")
            previous = rank
            bid_seat = next_seat
            doubled = redoubled = False
        elif normalized in ("DB", "RD"):
            if normalized == "DB":
                doubled = True
            else:
                redoubled = True
        next_seat = (next_seat + 1) % 4
    if BID.fullmatch(bid):
        return bid_rank(bid) > previous
    if bid in ("X", "DB", "DOUBLE"):
        return bid_seat is not None and not doubled and (next_seat - bid_seat) % 2 == 1
    if bid in ("XX", "RD", "REDOUBLE"):
        return doubled and not redoubled and bid_seat is not None and (next_seat - bid_seat) % 2 == 0
    return False


def validate_fixture(f: dict) -> None:
    validate_hand(f.get("hand"))
    if not isinstance(f.get("id"), str) or not re.fullmatch(r"[a-z0-9_-]+", f["id"]):
        raise BenchmarkError("invalid fixture id")
    if f.get("dealer") not in SEATS or f.get("seat") not in SEATS:
        raise BenchmarkError("invalid fixture seat/dealer")
    calls = parse_context(f.get("ctx", ""))
    if SEATS[(SEATS.index(f["dealer"]) + len(calls)) % 4] != f["seat"]:
        raise BenchmarkError("fixture next turn is not requested seat")
    if f.get("vul") not in ("", "NS", "EW", "Both"):
        raise BenchmarkError("invalid fixture vulnerability")
    # Fixture histories have no doubles / redoubles and must not be terminal.
    highest = -1
    for call in calls:
        if BID.fullmatch(call.upper()):
            if bid_rank(call.upper()) <= highest:
                raise BenchmarkError("fixture contains nonascending bids")
            highest = bid_rank(call.upper())
        elif call.upper() not in ("--",):
            raise BenchmarkError("fixture has unsupported double/redouble")
    if len(calls) >= 4 and calls[-4:] == ["--"] * 4:
        raise BenchmarkError("terminal auction fixture")
    if highest >= 0 and calls[-3:] == ["--"] * 3:
        raise BenchmarkError("terminal contract fixture")


def fixtures_from_json(path: Path) -> list[dict]:
    try:
        all_rows = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(all_rows, list) or len(all_rows) < 8:
            raise BenchmarkError("at least eight real-fixture scenarios required")
        seen = set()
        for f in all_rows:
            if not isinstance(f, dict):
                raise BenchmarkError("fixture must be an object")
            validate_fixture(f)
            if f["id"] in seen:
                raise BenchmarkError("duplicate fixture id")
            seen.add(f["id"])
        return all_rows
    except (OSError, UnicodeError, ValueError) as exc:
        raise BenchmarkError("invalid fixture file") from exc


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def get_json(origin: str, route: str, query: dict | None = None, *, timeout: float = 65.) -> dict:
    safe = loopback_url(origin)
    # ProxyHandler({}) blocks environment proxy settings, redirects disabled.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    uri = safe.rstrip("/") + route
    if query:
        uri += "?" + urllib.parse.urlencode(query)
    try:
        with opener.open(urllib.request.Request(uri, headers={"Accept": "application/json"}),
                         timeout=timeout) as res:
            raw = res.read(MAX_BYTES + 1)
            if len(raw) > MAX_BYTES:
                raise BenchmarkError("BEN response exceeds size cap")
            data = json.loads(raw.decode("utf-8"))
        if not isinstance(data, dict):
            raise BenchmarkError("BEN returned nonobject JSON")
        return data
    except (urllib.error.URLError, TimeoutError, OSError, ValueError) as exc:
        raise BenchmarkError("BEN request failed (URL and hand intentionally redacted)") from exc


def read_rss(pid: int) -> int:
    """KiB, including real process memory; no assumption about target VPS."""
    try:
        for line in Path(f"/proc/{pid}/status").read_text().splitlines():
            if line.startswith("VmRSS:"):
                return int(line.split()[1])
    except (OSError, ValueError):
        pass
    return 0


def verify_capabilities(url: str) -> dict:
    data = get_json(url, "/")
    playable = data.get("playsSystems")
    reads = data.get("readsSystems")
    if not isinstance(playable, list) or not isinstance(reads, list) or not set(REQUIRED).issubset(set(playable)):
        raise BenchmarkError("required live BEN multi-system capabilities unavailable")
    if "PRECISION" in playable:
        raise BenchmarkError("unexpected precision capability; update assumptions before evaluation")
    return {"playsSystems": playable, "readsSystemCount": len(reads),
            "default": data.get("defaults", {}).get("ourSystem")}


def query_bid(url: str, fixture: dict, system: str, *, timeout: float) -> dict:
    q = {k: fixture[k] for k in ("hand", "seat", "dealer", "vul", "ctx")}
    q.update({"ourSystem": system, "theirSystem": "21GF", "matchtype": "IMP"})
    started = time.perf_counter()
    data = get_json(url, "/bid", q, timeout=timeout)
    ms = (time.perf_counter() - started) * 1000.0
    bid = data.get("bid")
    if not isinstance(bid, str) or not legal_next(fixture["ctx"], bid):
        raise BenchmarkError("BEN returned missing or illegal auction proposal")
    return {"fixture": fixture["id"], "system": system, "bid": bid,
            "latencyMs": round(ms, 1), "legalPrecheck": True}


def reject_unknown(url: str, fixture: dict) -> bool:
    q = {k: fixture[k] for k in ("hand", "seat", "dealer", "vul", "ctx")}
    q.update({"ourSystem": "UNSUPPORTED-NEVER-USE", "theirSystem": "SAYC"})
    base = loopback_url(url)
    req = urllib.request.Request(base + "bid?" + urllib.parse.urlencode(q))
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    try:
        with opener.open(req, timeout=15):
            return False
    except urllib.error.HTTPError as exc:
        return exc.code == 400
    except (urllib.error.URLError, TimeoutError):
        return False


def percentile(values: list[float], p: int) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    idx = max(0, math.ceil(len(ordered) * (p / 100)) - 1)
    return round(ordered[idx], 1)


def measure(rows: list[dict]) -> dict:
    v = [r["latencyMs"] for r in rows]
    return {"requests": len(v), "p50ms": percentile(v, 50), "p95ms": percentile(v, 95),
            "p99ms": percentile(v, 99), "maxMs": max(v) if v else None}


def run_m13(url: str, fixtures: list[dict], *, timeout: float = 65., pid: int | None = None) -> dict:
    capabilities = verify_capabilities(url)
    if not reject_unknown(url, fixtures[0]):
        raise BenchmarkError("unknown ourSystem did not fail closed")
    # Every request passes an explicit system; no unlabelled default fallback.
    results = []
    for f in fixtures:
        for system in REQUIRED:
            results.append(query_bid(url, f, system, timeout=timeout))
    by_id = {}
    for row in results:
        by_id.setdefault(row["fixture"], {})[row["system"]] = row["bid"]
    different = [k for k, v in by_id.items() if v["21GF"] != v["SAYC"]]
    # A system's rules are not proven by a different chosen bid alone. Test
    # high-confidence forcing constraints, but never silently omit violations.
    violations = []
    forcing = {"2over1_opener", "2over1_responder", "forcing_nt_opener"}
    for row in results:
        f = next(f for f in fixtures if f["id"] == row["fixture"])
        if row["system"] == "21GF" and f.get("check") in forcing and row["bid"].upper() in ("PASS", "P", "--", "PA"):
            violations.append({"fixture": f["id"], "system": "21GF", "violation": "PASS_IN_FORCING_SEQUENCE"})
    return {
        "status": "PASS" if not violations else "SEMANTIC_REVIEW_REQUIRED",
        "scope": "REAL_BEN_BID_A_B_SMALL_UNREVIEWED_FIXTURES",
        "capabilities": capabilities,
        "requests": len(results),
        "distinctFixtures": len(fixtures),
        "comparativeDifferences": len(different),
        "differingFixtureIds": different,
        "forcingViolations": violations,
        "bidProposals": results,  # fixture IDs & result; NEVER hands or GET query
        "bySystem": {s: measure([x for x in results if x["system"] == s]) for s in REQUIRED},
        "rssAtEndKiB": read_rss(pid) if pid else None,
        "expertReviewed": False,
        "qualityOrWinRateProven": False,
        "bridgeCoreReplayed": False,
    }


def run_batch(url: str, fxs: list[dict], workers: int, timeout: float) -> tuple[list[dict], float]:
    start = time.perf_counter()
    if workers == 1:
        results = [query_bid(url, f, REQUIRED[i % 2], timeout=timeout) for i, f in enumerate(fxs)]
    else:
        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
            futures = [pool.submit(query_bid, url, f, REQUIRED[i % 2], timeout=timeout)
                       for i, f in enumerate(fxs)]
            results = [f.result(timeout=timeout + 10) for f in futures]
    return results, time.perf_counter() - start


def run_m14(url: str, fixtures: list[dict], *, pid: int | None = None,
            secondary_url: str | None = None, secondary_pid: int | None = None,
            timeout: float = 65., rounds: int = 1) -> dict:
    verify_capabilities(url)
    first = fixtures[:4] * rounds
    perf: dict = {}
    for level in (1, 2, 4):
        before = read_rss(pid) if pid else None
        result, duration = run_batch(url, first, level, timeout)
        perf[f"singleWorker_c{level}"] = {
            **measure(result), "elapsedSec": round(duration, 2),
            "throughputReqPerSec": round(len(result) / max(duration, 0.001), 3),
            "rssBeforeKiB": before, "rssAfterKiB": read_rss(pid) if pid else None,
        }
    secondary = None
    if secondary_url:
        verify_capabilities(secondary_url)
        half = first[: max(2, len(first) // 2)]
        started = time.perf_counter()
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            a = executor.submit(run_batch, url, half, 1, timeout)
            b = executor.submit(run_batch, secondary_url, half, 1, timeout)
            first_result, _ = a.result(timeout=timeout * len(half) + 10)
            second_result, _ = b.result(timeout=timeout * len(half) + 10)
        elapsed = time.perf_counter() - started
        secondary = {"requests": len(first_result) + len(second_result),
                     "elapsedSec": round(elapsed, 2),
                     "throughputReqPerSec": round((len(first_result) + len(second_result))/max(elapsed,.001),3),
                     "primaryRssKiB": read_rss(pid) if pid else None,
                     "secondaryRssKiB": read_rss(secondary_pid) if secondary_pid else None,
                     "combinedRssKiB": sum([read_rss(p) for p in (pid, secondary_pid) if p]),
                     "independentWorkers": True}
    return {"status":"PASS", "scope":"BEN_ISOLATED_CI_CAPACITY_SAMPLE_NOT_VPS_PRODUCTION",
            "sampleFixtureCount": len(fixtures), "perBatchRequestCount": len(first),
            "stats": perf, "twoProcess": secondary,
            "targetVps4gb": "NOT_TESTED_ON_TARGET_HOST",
            "productionRecommendation": "NO_GO_UNTIL_TARGET_CAPACITY_SECURITY_AND_LICENSE_REVIEW",
            "licenseApproved": False}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("m13", "m14"), required=True)
    parser.add_argument("--url", required=True)
    parser.add_argument("--fixtures", type=Path, default=Path("scripts/fixtures/ben_multisystem_m13.json"))
    parser.add_argument("--pid", type=int)
    parser.add_argument("--secondary-url")
    parser.add_argument("--secondary-pid", type=int)
    parser.add_argument("--timeout", type=float, default=65.)
    parser.add_argument("--rounds", type=int, default=1)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        if args.rounds not in (1, 2) or not 10 <= args.timeout <= 120:
            raise BenchmarkError("invalid benchmark limits")
        fxs = fixtures_from_json(args.fixtures)
        output = (run_m13(args.url, fxs, timeout=args.timeout, pid=args.pid)
                  if args.mode=="m13" else run_m14(args.url, fxs, pid=args.pid,
                     secondary_url=args.secondary_url, secondary_pid=args.secondary_pid,
                     timeout=args.timeout, rounds=args.rounds))
    except (BenchmarkError, concurrent.futures.TimeoutError) as exc:
        output = {"status":"FAIL", "reason":str(exc) if isinstance(exc, BenchmarkError) else "benchmark timeout",
                  "scope":args.mode, "realBiddingValidated":False}
    # Do not include URL (which contains the private hand) or raw upstream response.
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({k:v for k,v in output.items() if k not in ("bidProposals", "stats")},
                     sort_keys=True))
    return 0 if output["status"]=="PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
