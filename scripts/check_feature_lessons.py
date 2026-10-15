#!/usr/bin/env python3
"""Minimal PR gate for feature lessons. Human review verifies one note per feature."""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Callable, Iterable

LESSON_DIR = "docs/learning/features/"
INDEX = "docs/learning/INDEX.md"
REQUIRED_SECTIONS = (
    "## 功能目的與實際情境",
    "## 主要程式碼導讀",
    "## 為什麼這樣設計",
    "## 驗證與實際證據",
    "## 練習與自我檢驗",
)
SOURCE_EXTENSIONS = (".dart", ".py", ".kt", ".java", ".swift",
                     ".ts", ".tsx", ".js", ".jsx", ".go")


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
    source = sorted(p for p in changed if is_behavior_source(p))
    notes = sorted(p for p in changed if p.startswith(LESSON_DIR) and p.endswith(".md"))
    errors: list[str] = []
    if source and not notes:
        errors.append("Feature source changed without a lesson under " + LESSON_DIR)
    if source and INDEX not in changed:
        errors.append("Feature source changed without updating " + INDEX)
    for path in notes:
        match = re.fullmatch(r"M(\d+)_F(\d+)_[A-Z0-9_]+", Path(path).stem)
        if not match:
            errors.append("Invalid note path (expect Mx_Fxx_TOPIC.md): " + path)
            continue
        feature_id = "M" + str(int(match.group(1))) + "-F" + str(int(match.group(2))).zfill(2)
        try:
            body = reader(path)
        except (OSError, UnicodeError, KeyError) as exc:
            errors.append("Cannot read note: " + path + ": " + str(exc))
            continue
        if ("- Feature ID：" + feature_id not in body and
                "- Feature ID: " + feature_id not in body):
            errors.append(path + " is missing Feature ID " + feature_id)
        for section in REQUIRED_SECTIONS:
            if section not in body:
                errors.append(path + " is missing " + section)
        try:
            index = reader(INDEX)
        except (OSError, UnicodeError, KeyError) as exc:
            errors.append("Cannot read " + INDEX + ": " + str(exc))
        else:
            if feature_id not in index or Path(path).name not in index:
                errors.append("Missing " + feature_id + " note link in " + INDEX)
    return errors


def changed_files(base: str, head: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=ACMRT", base, head],
        capture_output=True, check=True, text=True,
    )
    return [p for p in result.stdout.splitlines() if p]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", help="PR base commit SHA")
    parser.add_argument("--head", help="PR head commit SHA")
    parser.add_argument("--paths", nargs="*", help="Test explicit changed paths")
    args = parser.parse_args()
    if args.paths is None and not (args.base and args.head):
        parser.error("Pass --base and --head, or --paths")
    try:
        paths = args.paths if args.paths is not None else changed_files(args.base, args.head)
        errors = check(paths, lambda p: Path(p).read_text(encoding="utf-8"))
    except subprocess.CalledProcessError as exc:
        print("Git diff failed: " + str(exc), file=sys.stderr)
        return 2
    if errors:
        for error in errors:
            print("ERROR: " + error, file=sys.stderr)
        print("Review docs/learning/README.md and the feature template.", file=sys.stderr)
        return 1
    print("PASS: lesson presence, headings and index link for "
          + str(len(paths)) + " changed files. One-note-per-feature remains a PR review task.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

