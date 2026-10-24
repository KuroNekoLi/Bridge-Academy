#!/usr/bin/env python3
"""M3.3: isolated, research-only native BBA Meckwell bid sidecar.

Run only against the reviewed BEN SHA with --research-only. Handles a single
private robot hand via POST on literal 127.0.0.1; never logs requests, paths
with hands, raw native exceptions, or binary contents. It is NOT a production
Gateway or a whole-game bridge bot.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import platform
import re
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Callable

from precision_m3_probe import (
    PINNED_BEN, PINNED_SELECTED_CARD_SHA256, PRECISION_CC,
    ResearchError, check_ben_source, parse_hand, summarize_candidate,
)

PROFILE_ID = "BA-PRECISION-MECKWELL"
REVISION = 1
PROVIDER = "BBA_NATIVE_EPBOT"
BID_ROUTE = "/v1/precision/bid"
HEALTH_ROUTE = "/health"
NATIVE_SHA256 = "c35d00b7aacdb5fe7bd4a5aeb1f5cdacef9856f9fc7b4ff4048368b6827777b4"
OPPONENT_CARDS = {"21GF": "BBA/CC/BEN-21GF.bbsa",
                  "SAYC": "BBA/CC/BEN-SAYC.bbsa"}
EXPECTED_FIELDS = {
    "version", "profileId", "revision", "cardSha256", "opponentModel",
    "seat", "dealer", "vul", "ctx", "hand",
}
ALLOWED_CALL = re.compile(r"(?:P|X|XX|[1-7][CDHSN])")
ALLOWED_OUTPUT = re.compile(r"(?:PASS|X|XX|[1-7][CDHSN])")
SEATS = "NESW"


class PrecisionProtocolError(Exception):
    pass


def parse_auction(ctx: str) -> list[str]:
    if not isinstance(ctx, str) or len(ctx) > 240:
        raise PrecisionProtocolError("invalid_auction")
    if not ctx:
        return []
    calls = ctx.split("-")
    if len(calls) > 64 or any(not ALLOWED_CALL.fullmatch(c) for c in calls):
        raise PrecisionProtocolError("invalid_auction")
    # Never request a bidder after a terminal auction. The Bridge Core
    # remains the authoritative source of actual legality and turn validity.
    normalized = ["PASS" if c == "P" else c for c in calls]
    if normalized[-4:] == ["PASS"] * 4:
        raise PrecisionProtocolError("terminal_auction")
    if (len(normalized) >= 4 and normalized[-3:] == ["PASS"] * 3 and
            any(re.fullmatch(r"[1-7][CDHSN]", v) for v in normalized)):
        raise PrecisionProtocolError("terminal_auction")
    return normalized


def validate_request(body: object) -> tuple[dict, list[str]]:
    if not isinstance(body, dict) or set(body) != EXPECTED_FIELDS:
        raise PrecisionProtocolError("invalid_schema")
    if (type(body["version"]) is not int or body["version"] != 1 or
            type(body["revision"]) is not int or body["revision"] != REVISION or
            body["profileId"] != PROFILE_ID or
            body["cardSha256"] != PINNED_SELECTED_CARD_SHA256):
        raise PrecisionProtocolError("unknown_precision_version")
    if body["opponentModel"] not in OPPONENT_CARDS:
        raise PrecisionProtocolError("unknown_opponent_model")
    if body["seat"] not in SEATS or body["dealer"] not in SEATS:
        raise PrecisionProtocolError("invalid_seat")
    if body["vul"] not in ("", "NS", "EW", "Both"):
        raise PrecisionProtocolError("invalid_vulnerability")
    if not isinstance(body["hand"], str):
        raise PrecisionProtocolError("invalid_hand")
    try:
        parse_hand(body["hand"])
    except ResearchError:
        raise PrecisionProtocolError("invalid_hand") from None
    auction = parse_auction(body["ctx"])
    expected = SEATS[(SEATS.index(body["dealer"]) + len(auction)) % 4]
    if body["seat"] != expected:
        raise PrecisionProtocolError("actor_turn_mismatch")
    return body, auction


def verify_vendor(ben_root: Path) -> tuple[Path, dict[str, Path]]:
    check_ben_source(ben_root)
    cc = summarize_candidate(ben_root)
    if cc["cardSha256"] != PINNED_SELECTED_CARD_SHA256:
        raise ResearchError("Meckwell V1 card SHA mismatch")
    if platform.system() != "Linux" or platform.machine().lower() not in (
            "x86_64", "amd64"):
        raise ResearchError("M3.3 native research runner must be Linux x64")
    native = ben_root / "bin/BBA/linux/x64/libEPBot.so"
    if not native.is_file() or native.is_symlink():
        raise ResearchError("missing trusted native EPBot")
    if hashlib.sha256(native.read_bytes()).hexdigest() != NATIVE_SHA256:
        raise ResearchError("native binary version mismatch")
    others = {name: ben_root / path for name, path in OPPONENT_CARDS.items()}
    if any(not f.is_file() or f.is_symlink() for f in others.values()):
        raise ResearchError("missing fixed opponent cards")
    return ben_root / PRECISION_CC, others


class NativePrecisionEngine:
    def __init__(self, ben_root: Path):
        root = ben_root.resolve()
        self.precision_cc, self.opponent_cards = verify_vendor(root)
        # Only import the upstream ctypes wrapper after provenance checks pass.
        sys.path.insert(0, str((root / "src").resolve()))
        sys.path.insert(0, str(root))
        from bba.BBA import BBABotBid
        self._builder = BBABotBid

    def decide(self, body: object) -> dict:
        req, auction = validate_request(body)
        seat = SEATS.index(req["seat"])
        dealer = SEATS.index(req["dealer"])
        vul = req["vul"]
        # BBA.py.bba_vul computes EW + NS*2; its input is (NS, EW).
        vulnerabilities = (vul in ("NS", "Both"), vul in ("EW", "Both"))
        bot = self._builder(
            str(self.precision_cc),
            str(self.opponent_cards[req["opponentModel"]]),
            seat, req["hand"], vulnerabilities, dealer, False, False,
        )
        output = bot.bid(auction).bid
        if not isinstance(output, str) or not ALLOWED_OUTPUT.fullmatch(output):
            raise PrecisionProtocolError("invalid_native_bid")
        return {
            "bid": output, "provider": PROVIDER, "profileId": PROFILE_ID,
            "revision": REVISION, "cardSha256": PINNED_SELECTED_CARD_SHA256,
        }


def handler_factory(decider: Callable[[object], dict]):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"
        def log_message(self, *args):
            # Default BaseHTTPRequestHandler logs paths, clients and tokens.
            return

        def respond(self, status: int, payload: dict):
            raw = json.dumps(payload, separators=(",", ":")).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def do_GET(self):
            if self.path != HEALTH_ROUTE:
                self.respond(404, {"error": "not_found"})
                return
            self.respond(200, {
                "status": "research_ready", "profileId": PROFILE_ID,
                "revision": REVISION, "cardSha256": PINNED_SELECTED_CARD_SHA256,
                "sourceCommit": PINNED_BEN, "provider": PROVIDER,
            })

        def do_POST(self):
            if self.path != BID_ROUTE or self.headers.get("Content-Type", "").split(";")[0] != "application/json":
                self.respond(404, {"error": "invalid_route"})
                return
            length = self.headers.get("Content-Length")
            if length is None or not length.isascii() or not length.isdecimal() or not 0 < int(length) <= 2048:
                self.respond(413, {"error": "request_size"})
                return
            try:
                raw = self.rfile.read(int(length))
                payload = json.loads(raw)
                result = decider(payload)
            except (UnicodeError, ValueError, PrecisionProtocolError):
                self.respond(400, {"error": "invalid_request"})
                return
            except Exception:
                # Native exceptions can contain private hand details.
                self.respond(503, {"error": "native_unavailable"})
                return
            self.respond(200, result)

    return Handler


class LocalResearchServer(HTTPServer):
    request_queue_size = 4
    allow_reuse_address = False


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--ben-root", type=Path, required=True)
    p.add_argument("--port", type=int, default=18088)
    p.add_argument("--research-only", action="store_true")
    args = p.parse_args()
    if not args.research_only or not (1025 <= args.port <= 65535):
        print("M3.3 research-only permission/port required", file=sys.stderr)
        return 2
    try:
        engine = NativePrecisionEngine(args.ben_root)
        server = LocalResearchServer(("127.0.0.1", args.port),
                                     handler_factory(engine.decide))
    except (OSError, ResearchError, ImportError):
        print("M3.3 native worker initialization failed (redacted)",
              file=sys.stderr)
        return 1
    print("M3_3_EPBOT_RESEARCH_READY", flush=True)
    try:
        server.serve_forever(poll_interval=0.2)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
