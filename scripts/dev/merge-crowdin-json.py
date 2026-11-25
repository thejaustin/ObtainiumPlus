#!/usr/bin/env python3
"""Merge a Crowdin download into the repo's translation files, safely.

Crowdin's plain JSON export flattens plural entries ({"one": ..., "other": ...})
to the source's two forms, which would drop forms a language needs (Russian
"few", Arabic "zero"/"two"...). It also writes the English source text for
anything untranslated. So the download is never used as is: for each locale
file this script takes only plain-string translations that differ from the
English source, and keeps everything else (plurals, strings Crowdin has no
translation for, key order) as the repo had it before the download.

Usage: merge-crowdin-json.py BEFORE_DIR [TRANSLATIONS_DIR]
  BEFORE_DIR        copy of assets/translations taken before the download
  TRANSLATIONS_DIR  directory the download wrote to (default assets/translations)
"""
import glob
import json
import os
import sys


def indent_of(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    for line in text.split("\n")[1:]:
        stripped = line.lstrip(" ")
        if stripped:
            return len(line) - len(stripped) or 2
    return 2


def main():
    before_dir = sys.argv[1]
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "assets/translations"
    en = json.load(open(os.path.join(out_dir, "en.json"), encoding="utf-8"))
    taken = kept = 0
    for path in sorted(glob.glob(os.path.join(out_dir, "*.json"))):
        name = os.path.basename(path)
        if name in ("en.json", "package.json", "package-lock.json"):
            continue
        before_path = os.path.join(before_dir, name)
        if not os.path.exists(before_path):
            continue
        before = json.load(open(before_path, encoding="utf-8"))
        downloaded = json.load(open(path, encoding="utf-8"))
        merged = {}
        for key, source in en.items():
            if isinstance(source, dict):
                merged[key] = before.get(key) if isinstance(before.get(key), dict) else source
                continue
            new = downloaded.get(key)
            if isinstance(new, str) and new.strip() and new != source:
                merged[key] = new
                taken += new != before.get(key)
            else:
                merged[key] = before.get(key, source)
                kept += 1
        with open(path, "w", encoding="utf-8") as f:
            json.dump(merged, f, ensure_ascii=False, indent=indent_of(before_path))
            f.write("\n")
    print(f"merged: {taken} changed translations, {kept} kept from the repo")


if __name__ == "__main__":
    main()
