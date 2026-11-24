# Release checklist

Releases are cut by CI (`.github/workflows/build-apk.yml`) on every push to `main`.
This list is what to verify around that.

## Before pushing
- [ ] `flutter test --reporter failures-only` passes
- [ ] `bash scripts/dev/analyze-live.sh` reports 0 live errors
- [ ] `python3 scripts/dev/check-translations.py` is clean (every locale has every `en.json` key)
- [ ] `CHANGELOG_USER.md` `[Upcoming]` has entries in the format `- **Title** — a few words`,
      grouped under ✨ New / ⚡ Faster / 🎨 Design / 🐛 Fixed / 🔧 Other. User-facing only.
      An empty `[Upcoming]` makes CI fall back to raw commit logs.
- [ ] Commit subjects follow Conventional Commits (`feat:`, `fix:`, `perf:`, `docs:` …); the lint job enforces it
- [ ] `git fetch origin && git merge origin/main --no-edit` (CI bumps versions)
- [ ] No Build APK run in progress (`scripts/dev/ci-status.sh`); two overlapping runs can fail the version-bump rebase

## After CI
- [ ] `scripts/dev/ci-status.sh --log` green; release body reads well on GitHub
- [ ] `scripts/dev/device-smoke.sh` on a phone with the new APK installed (no crashes, app foregrounded)
- [ ] Open What's New, Settings, one app's detail page; pull to refresh
- [ ] Release builds strip asserts: re-run any suspicious UI path in a debug build or widget test too
