#!/usr/bin/env python3
"""Validate ObtainiumPlus translation JSON files.

Catches:
1. Invalid JSON syntax.
2. Argument count mismatches against en.json (positional {} arguments).
3. Named argument mismatches against en.json (e.g. {n}, {before}, {after}).
4. Unknown custom placeholders introduced in translations.

Usage: python3 scripts/dev/check-translations.py [file ...]
Exits with 1 if problems are detected, 0 if all translations are valid.
"""
import glob
import json
import os
import re
import sys

FMT_PATTERN = re.compile(r"\{([^}]*)\}")
PLURAL_KEYS = {"zero", "one", "two", "few", "many", "other"}


def extract_leaves(data, prefix=""):
    out = {}
    for k, v in data.items():
        full = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            if any(sub in PLURAL_KEYS for sub in v.keys()):
                out[full] = (
                    True,
                    {
                        sub_k: FMT_PATTERN.findall(sub_v)
                        for sub_k, sub_v in v.items()
                        if isinstance(sub_v, str)
                    },
                )
            else:
                out.update(extract_leaves(v, full))
        elif isinstance(v, str):
            out[full] = (False, FMT_PATTERN.findall(v))
    return out


def main():
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    en_path = os.path.join(root, "assets", "translations", "en.json")
    if not os.path.exists(en_path):
        print(f"Error: Base translation file not found at {en_path}", file=sys.stderr)
        return 1

    try:
        with open(en_path, encoding="utf-8") as f:
            en_data = json.load(f)
    except Exception as e:
        print(f"Error reading {en_path}: {e}", file=sys.stderr)
        return 1

    en_leaves = extract_leaves(en_data)

    if len(sys.argv) > 1:
        files = sys.argv[1:]
    else:
        files = sorted(glob.glob(os.path.join(root, "assets", "translations", "*.json")))

    problems = []

    for path in files:
        if os.path.abspath(path) == os.path.abspath(en_path):
            continue
        fname = os.path.basename(path)
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            problems.append(f"{fname}: JSON parse error: {e}")
            continue

        t_leaves = extract_leaves(data)
        for key, (is_plural, en_fmts) in en_leaves.items():
            if key not in t_leaves:
                continue
            t_is_plural, t_fmts = t_leaves[key]
            if not is_plural and not t_is_plural:
                if len(en_fmts) != len(t_fmts):
                    problems.append(
                        f"{fname}: '{key}' argument count mismatch (en={en_fmts}, trans={t_fmts})"
                    )
                elif any(e != t and e != "" for e, t in zip(en_fmts, t_fmts)):
                    problems.append(
                        f"{fname}: '{key}' named argument mismatch (en={en_fmts}, trans={t_fmts})"
                    )
            elif is_plural and t_is_plural:
                en_expected = set()
                for fmts in en_fmts.values():
                    en_expected.update(fmts)
                for sub_k, sub_fmts in t_fmts.items():
                    for p in sub_fmts:
                        if p and p not in en_expected:
                            problems.append(
                                f"{fname}: '{key}.{sub_k}' introduces unknown placeholder '{{{p}}}' (en uses {sorted(en_expected)})"
                            )

    if problems:
        print(f"Translation validation failed with {len(problems)} problem(s):")
        for p in problems:
            print(f"  - {p}")
        return 1

    print(f"All {len(files)} translation file(s) OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
