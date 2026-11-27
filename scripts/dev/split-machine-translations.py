#!/usr/bin/env python3
"""Move AI-written strings out of the locale files into assets/translations/machine/.

Reads docs/translation-provenance.json (ai_keys per locale, from
translation-provenance.py). In each locale file the moved keys go back to the
English text (the "untranslated" state human translators and Crowdin expect);
the AI text goes to machine/<locale>.json, which the app only uses when the
user turns on "Machine translations". Safe to re-run: keys already moved are skipped.
"""
import json, os

ROOT = "assets/translations"
en = json.load(open(f"{ROOT}/en.json", encoding="utf-8"))
ai = json.load(open("docs/translation-provenance.json", encoding="utf-8"))["ai_keys"]
os.makedirs(f"{ROOT}/machine", exist_ok=True)
moved = 0
for name, keys in sorted(ai.items()):
    path = f"{ROOT}/{name}"
    loc = json.load(open(path, encoding="utf-8"))
    mpath = f"{ROOT}/machine/{name}"
    machine = json.load(open(mpath, encoding="utf-8")) if os.path.exists(mpath) else {}
    for k in keys:
        if k in loc and loc[k] != en[k]:
            machine[k] = loc[k]
            loc[k] = en[k]
            moved += 1
    indent = 4 if '\n    "' in open(path, encoding="utf-8").read() else 2
    with open(path, "w", encoding="utf-8") as f:
        json.dump(loc, f, ensure_ascii=False, indent=indent)
        f.write("\n")
    if machine:
        with open(mpath, "w", encoding="utf-8") as f:
            json.dump(dict(sorted(machine.items())), f, ensure_ascii=False, indent=2)
            f.write("\n")
print(f"moved {moved} AI-written strings")
