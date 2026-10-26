#!/usr/bin/env python3
"""Require the consolidated implementation ledger/lesson on behavior changes."""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess
import sys
from typing import Callable, Iterable

NOTE = "docs/implemented/ENGINEERING_NOTES.md"
INDEX = "docs/implemented/FEATURES.md"
REQUIRED_SECTIONS = (
    "# 已完成功能的工程導讀",
    "## 功能更新時的筆記規格",
)
SOURCE_EXTENSIONS = (".dart", ".py", ".kt", ".java", ".swift", ".ts", ".tsx", ".js", ".jsx", ".go")


def is_behavior_source(path: str) -> bool:
    if not path.endswith(SOURCE_EXTENSIONS):
        return False
    if any(x in path for x in ("/test/", "/tests/", "/__tests__/")):
        return False
    if path.endswith(("_test.dart", "_test.py", ".test.ts", ".spec.ts")):
        return False
    if path.startswith("packages/"):
        return "/lib/" in path or "/src/" in path
    if path.startswith("apps/") or path.startswith("services/"):
        return not path.endswith(("_test.kt", "_test.go"))
    return False


def check(paths: Iterable[str], reader: Callable[[str], str]) -> list[str]:
    changed = set(paths)
    production = sorted(p for p in changed if is_behavior_source(p))
    errors: list[str] = []
    if production and NOTE not in changed:
        errors.append("Feature source changed without updating " + NOTE)
    if production and INDEX not in changed:
        errors.append("Feature source changed without updating " + INDEX)
    if NOTE in changed:
        try:
            body = reader(NOTE)
        except (OSError, UnicodeError, KeyError) as exc:
            return errors + ["Cannot read note: " + str(exc)]
        for section in REQUIRED_SECTIONS:
            if section not in body:
                errors.append(NOTE + " missing " + section)
        if not re.search(r"(?m)^## M\d+-F\d+\s*[｜|]", body):
            errors.append(NOTE + " missing identifiable Mx-Fxx feature lesson")
    if INDEX in changed:
        try:
            page = reader(INDEX)
        except (OSError, UnicodeError, KeyError) as exc:
            errors.append("Cannot read feature index: " + str(exc))
        else:
            if not page.startswith("# 已實作功能"):
                errors.append(INDEX + " missing feature status heading")
    return errors


def changed_files(base: str, head: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=ACMRT", base, head],
        capture_output=True, check=True, text=True,
    )
    return [p for p in result.stdout.splitlines() if p]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base")
    parser.add_argument("--head")
    parser.add_argument("--paths", nargs="*")
    args = parser.parse_args()
    if args.paths is None and not (args.base and args.head):
        parser.error("Pass --base/--head or --paths")
    try:
        paths = args.paths if args.paths is not None else changed_files(args.base, args.head)
        errors = check(paths, lambda p: Path(p).read_text(encoding="utf-8"))
    except subprocess.CalledProcessError as exc:
        print("Git diff failed: " + str(exc), file=sys.stderr)
        return 2
    if errors:
        for error in errors:
            print("ERROR: " + error, file=sys.stderr)
        return 1
    print("PASS: canonical feature inventory and engineering note gate", len(paths))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
