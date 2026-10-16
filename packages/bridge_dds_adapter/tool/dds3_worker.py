#!/usr/bin/env python3
"""No-network, single-shot DDS3 worker. PRIVATE fixture/PBN enters via stdin.

The process must run only after Bridge Core validates a trusted terminal
transcript. Never log the hand; never expose the worker through an HTTP API.
Pinned upstream: abb1127ba096676a4849f341f300c9827a732342.
"""
import json
import sys

COMMIT = "abb1127ba096676a4849f341f300c9827a732342"
RANKS = "23456789TJQKA"
STRAINS = "SHDC"


def _cards_from_pbn(pbn):
    parts = pbn.split()
    if len(parts) != 4 or not parts[0].startswith("N:"):
        raise ValueError("invalid")
    cards = [p[2:] if i == 0 else p for i, p in enumerate(parts)]
    seen = set()
    matrix = []
    for hand in cards:
        groups = hand.split(".")
        if len(groups) != 4:
            raise ValueError("invalid")
        holding = []
        count = 0
        for suit, ranks in zip(STRAINS, groups):
            value = 0
            for rank in ranks:
                if rank not in RANKS or (suit, rank) in seen:
                    raise ValueError("invalid")
                seen.add((suit, rank))
                count += 1
                value |= 1 << (RANKS.index(rank) + 2)
            holding.append(value)
        if count != 13:
            raise ValueError("invalid")
        matrix.append(holding)
    if len(seen) != 52:
        raise ValueError("invalid")
    return matrix


def main():
    try:
        # The input must never be printed on invalid requests.
        data = sys.stdin.buffer.read(513)
        if len(data) > 512:
            raise ValueError("invalid")
        request = json.loads(data.decode("utf-8"))
        if not isinstance(request, dict) or set(request) != {
            "schemaVersion", "pbn"
        } or request["schemaVersion"] != 1 or not isinstance(
            request["pbn"], str
        ):
            raise ValueError("invalid")
        cards = _cards_from_pbn(request["pbn"])
        from dds3 import calc_dd_table
        output = calc_dd_table({"cards": cards})
        rows = output["res_table"]
        if len(rows) != 5 or any(len(row) != 4 or any(
            type(cell) is not int or not 0 <= cell <= 13 for cell in row
        ) for row in rows):
            raise ValueError("invalid")
        response = {
            "schemaVersion": 1,
            "solverCommit": COMMIT,
            "engine": "dds3-python-calc_dd_table",
            "resTable": rows,
        }
        sys.stdout.write(json.dumps(response, separators=(",", ":")))
        sys.stdout.flush()
    except Exception:
        # Never include traceback, input, PBN, native stdout or internals.
        sys.stderr.write("DDS_WORKER_FAILURE\n")
        sys.exit(2)


if __name__ == "__main__":
    main()
