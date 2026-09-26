# Changelog

One line per change, with the why. Newest first.

## [0.3.2] - 2026-09-26

### Added
- `subpowers --version` (also `version`, `-v`): prints the version and the git commit, so a bug report can say exactly what ran.
- `docs/diagrams/architecture.md`: one diagram of how an image request flows from your agent to a saved file.
- Tests for `--version` and the first two fixes below (115 cases, up from 108).

### Changed
- One name for the Google painter in every doc: `google`. `antigravity` still works, so nothing breaks.
- One set of measured speeds in the README, SKILL.md and the help (they disagreed).
- README says up top that you need a paid plan and a Mac, instead of 100 lines down.
- README and CONTRIBUTING no longer call reference sets "next" (they shipped in 0.2).

### Fixed
- `subpowers storyboard ... --painter` with no value crashed with `$2: unbound variable`; every storyboard flag now says which one needs a value.
- The unknown-painter error listed `antigravity` and `all`; it now lists the names the README teaches: chatgpt, google, grok, council.
- CONTRIBUTING's pre-PR check skipped `bin/grok-image` and the Python helpers.

## [0.3.1] - 2026-09-25

### Fixed
- Fixes from the Dave and Drey audits: SIGPIPE under pipefail read a logged-in plan as OFF, timeouts on stock macOS, a paid paint is always delivered (exit 5, never painted twice), a dry helper model falls through, a fresh install with no logins exits 0.

### Added
- Stand-in CLIs and an end-to-end test of every painter, in CI on Ubuntu and macOS.

## [0.3] - 2026-09-25

### Added
- Council mode, the image library, `subpowers slideshow`, best-quality defaults, honest plan detection.

## [0.2] - 2026-09-25

### Added
- Grok painter, fan-out, fallback, reference sets, character sheets, storyboards.
