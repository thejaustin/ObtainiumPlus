# AGENTS.md — ObtainiumPlus Guidelines

## Fork Versioning & Upstream Sync Rules

- **Upstream Code & Version Alignment**:
  - When updating the version string to match upstream, ALL upstream commits and features MUST be merged first.
  - Never bump the base version string (e.g. `1.6.17` -> `1.7.1`) to match upstream without actually merging all upstream commits, features, and fixes from that release.
  - If a patch build is released before upstream is merged, retain the current base version and increment only the patch counter (`-p<N>`).

## Changelogs & Release Notes

- User-facing release notes belong in `CHANGELOG_USER.md` under `## [Upcoming]`.
- When releasing, CI automatically archives upcoming notes to `## [<version>] — YYYY-MM-DD` and leaves a fresh `## [Upcoming]` block.
- If `## [Upcoming]` is empty, CI automatically generates clean, categorized release notes from commit logs.
- The in-app changelog viewer unwraps `<details>` blocks and cleans Markdown so users always see accurate release notes on-device.
