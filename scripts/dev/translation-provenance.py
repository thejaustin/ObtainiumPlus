#!/usr/bin/env python3
"""Who wrote each translated string? Reports provenance per locale.

Classes (per plain-string key, from `git blame` on assets/translations):
  upstream-human   human whose translation commits also appear in upstream/main
                   (Obtainium contributors; matched by author because the fork's
                   merges don't keep upstream commit ids)
  fork-human       human who has no translation commit upstream (e.g. the fork owner)
  AI-generated     commit authored by, or co-authored (Co-authored-by trailer) with,
                   an AI assistant (Claude, Antigravity, Qwen, Gemini)
  crowdin          commit authored by the Crowdin sync bot (individual translators
                   are listed in Crowdin, not git; see docs/TRANSLATION_CREDITS.md)
  untranslated     value equals the English source (a placeholder, credited to no one)

Mass reformat commits that rewrote every file are skipped so blame sees through
them (IGNORE_REVS). Usage: translation-provenance.py [--credits docs/TRANSLATION_CREDITS.md] [--json docs/translation-provenance.json]
Needs `git fetch upstream` first.
"""
import argparse, collections, glob, json, os, re, subprocess, sys

UPSTREAM_IGNORE = ["962c00067", "fc4b778eb"]  # upstream whole-file rearranges
IGNORE_REVS = ["e0b212efe", "e9a48dd7d", "8fbffb296"]  # whole-file reformat commits
AI = re.compile(r"claude|antigravity|qwen|noreply@anthropic\.com|@example\.com", re.I)
BOT = re.compile(r"github-actions|crowdin", re.I)
FORK_OWNERS = {"thejaustin@users.noreply.github.com", "the.j.austin@gmail.com"}
SKIP = {"en.json", "package.json", "package-lock.json"}


def git(*a):
    return subprocess.check_output(["git", *a], stderr=subprocess.DEVNULL).decode("utf-8", "replace")


def english_history():
    """Every text en.json has ever had. Locale files were filled with English
    placeholders over time, and en.json has been reworded since, so an old
    English string in a locale file is still 'untranslated', not a translation."""
    out = git("log", "-p", "-U0", "--no-renames", "--format=", "--", "assets/translations/en.json")
    rx = re.compile(r'^\+\s*"[^"]+":\s*"(.*)",?$', re.M)
    texts = set()
    for m in rx.finditer(out):
        try:
            texts.add(json.loads('"' + m.group(1) + '"'))
        except ValueError:
            pass
    return texts


def first_seen(path):
    """(key, value) -> (sha, author, email) of the first commit that wrote exactly
    that text. Unlike blame, a later move, reindent or merge can't take the credit."""
    p = subprocess.Popen(["git", "log", "--reverse", "-p", "-U0", "--no-renames", "--format=@@C%x00%H%x00%an%x00%ae", "--", path],
                         stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    seen, cur = {}, (None, "", "")
    rx = re.compile(r'^\+\s*"([^"]+)":\s*"(.*)",?$')
    for raw in p.stdout:
        line = raw.decode("utf-8", "replace").rstrip("\n")
        if line.startswith("@@C\0"):
            cur = tuple(line[3:].split("\0")[1:])
            continue
        m = rx.match(line)
        if m:
            try:
                seen.setdefault((m.group(1), json.loads('"' + m.group(2) + '"')), cur)
            except ValueError:
                pass
    return seen


def upstream_authors(path):
    """key -> {value: (author, email)} from upstream/main blame, so strings the
    upstream maintainer merely committed are credited to the original author."""
    try:
        out = git("blame", "-w", *[f"--ignore-rev={r}" for r in UPSTREAM_IGNORE], "--line-porcelain", "upstream/main", "--", path).split("\n")
    except subprocess.CalledProcessError:
        return {}
    res, author, email = {}, None, None
    for line in out:
        if line.startswith("author "):
            author = line[7:]
        elif line.startswith("author-mail "):
            email = line[12:].strip("<>")
        elif line.startswith("\t"):
            m = re.match(r'\s*"([^"]+)":\s*"(.*)",?$', line[1:])
            if m:
                try:
                    v = json.loads('"' + m.group(2) + '"')
                except ValueError:
                    continue
                res.setdefault(m.group(1), {})[v] = (author, email)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--credits")
    ap.add_argument("--json")
    args = ap.parse_args()
    up = set(git("log", "upstream/main", "--format=%ae", "--", "assets/translations").split()) - FORK_OWNERS
    ai_commits = set(git("log", "--all", "-i", "-E", "--format=%H", "--grep=Co-authored-by:.*(Claude|Antigravity|Qwen|Gemini)", "--", "assets/translations").split())
    en = json.load(open("assets/translations/en.json", encoding="utf-8"))
    ign = [f"--ignore-rev={r}" for r in IGNORE_REVS]
    en_hist = english_history()
    manifest = collections.defaultdict(dict)
    per_locale, people = {}, collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    for path in sorted(glob.glob("assets/translations/*.json")):
        name = os.path.basename(path)
        if name in SKIP:
            continue
        loc = json.load(open(path, encoding="utf-8"))
        up_by_key = upstream_authors(path)
        origin = first_seen(path)
        counts = collections.Counter()
        for key, source in en.items():
            if isinstance(source, dict) or key not in loc:
                continue
            val = loc[key]
            up_who = up_by_key.get(key, {}).get(val)
            if val == source or val in en_hist:
                cls = "untranslated"
            elif up_who and up_who[1] not in FORK_OWNERS:
                cls = "upstream-human"  # same text as upstream: credit upstream's author
            else:
                sha, author, email = origin.get((key, val), (None, "", ""))
                if AI.search(author + email) or sha in ai_commits:
                    cls = "AI-generated"
                elif BOT.search(author + email):
                    cls = "crowdin"
                elif email in up:
                    cls, up_who = "upstream-human", (author, email)
                else:
                    cls, up_who = "fork-human", (author, email)
            counts[cls] += 1
            if cls in ("upstream-human", "fork-human"):
                people[name][up_who][cls] += 1
            manifest[name][key] = cls
        per_locale[name] = counts
    total = sum(per_locale.values(), collections.Counter())
    for n, c in per_locale.items():
        print(n.ljust(16), dict(c))
    print("TOTAL".ljust(16), dict(total))
    if args.json:
        json.dump({"counts": {n: dict(c) for n, c in per_locale.items()}, "ai_keys": {n: sorted(k for k, c in ks.items() if c == "AI-generated") for n, ks in manifest.items()}}, open(args.json, "w"), indent=1, ensure_ascii=False)
    if args.credits:
        write_credits(args.credits, people, total, per_locale)


def handle(author, email):
    m = re.match(r"(?:\d+\+)?([^@]+)@users\.noreply\.github\.com", email)
    return f"[@{m.group(1)}](https://github.com/{m.group(1)})" if m else author


def write_credits(path, people, total, per_locale):
    canon = {}
    merged = collections.defaultdict(lambda: collections.defaultdict(collections.Counter))
    for loc, who in people.items():
        for (a, e), c in who.items():
            h = handle(a, e)
            merged[canon.setdefault(h.lower().lstrip("[@"), h)][loc].update(c)
    rows = sorted(merged.items(), key=lambda kv: -sum(sum(c.values()) for c in kv[1].values()))
    human = total["upstream-human"] + total["fork-human"] + total["crowdin"]
    with open(path, "w", encoding="utf-8") as f:
        f.write("# Translation credits\n\n")
        f.write("Obtainium+ is translated by people, and this page exists to thank them. ")
        f.write("Generated by `scripts/dev/translation-provenance.py`; do not edit by hand.\n\n")
        f.write(f"**{human} strings** were written by human translators. ")
        f.write(f"{total['AI-generated']} more are AI-written drafts that no person has reviewed yet; ")
        f.write("they are listed separately, credited to no person, and are replaced as soon as a human translation is approved. ")
        f.write(f"{total['untranslated']} entries are still English.\n\n")
        f.write("## Human translators\n\n")
        f.write("Everyone below wrote the text that is in the app today. Upstream (Obtainium) translators are credited by their original author, not by whoever merged their work.\n\n")
        f.write("| Contributor | Strings | Languages |\n|---|---|---|\n")
        for who, locs in rows:
            n = sum(sum(c.values()) for c in locs.values())
            f.write(f"| {who} | {n} | {', '.join(sorted(l[:-5] for l in locs))} |\n")
        f.write("\nTranslators who work in [Crowdin](https://crowdin.com/project/obtainiumplus) are listed in `CROWDIN_CONTRIBUTORS.md`.\n")
        f.write("\n## By language\n\n| Language | Human | AI draft (unreviewed) | Still English |\n|---|---|---|---|\n")
        for n, c in sorted(per_locale.items()):
            h = c["upstream-human"] + c["fork-human"] + c["crowdin"]
            f.write(f"| {n[:-5]} | {h} | {c['AI-generated']} | {c['untranslated']} |\n")
        f.write("\n## AI-written drafts\n\n")
        f.write("Written or co-written by an AI assistant (commit author or `Co-authored-by` trailer). ")
        f.write("Native speakers: if you spot one of these in your language, replacing it in Crowdin is the most helpful thing you can do. ")
        f.write("`translation-provenance.json` lists which keys these are.\n")


if __name__ == "__main__":
    sys.exit(main())
