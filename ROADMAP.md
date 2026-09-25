<p align="center"><img src="assets/roadmap-studio.jpg" alt="A tiny photo studio with reference photos pinned to a corkboard" width="80%"></p>

# Roadmap

subpowers turns subscriptions people already pay for into powers any agent can use. Images are power #1. Here's where it goes next. Anything below is open for contributors: comment on the issue, or open one if it isn't there yet.

## Now (shipped)

- [x] Image power: ChatGPT painter (OpenAI's current image model through `codex`)
- [x] Image power: Antigravity painter (Nano Banana 2 through `agy`)
- [x] Reference photos (`--ref`), including iPhone HEIC
- [x] Receipt beside every image (prompt, model, C2PA signer, timings)
- [x] Always-newest helper model + daily codex update
- [x] `subpowers doctor` and a one-command installer for Claude Code, Codex and other agents

## Next: the Studio

The goal: save who you are once, and every agent can put you, your products and your world into any scene.

- [ ] **Reference sets**: `subpowers refs add me ~/Pictures/me-*.jpg`, then `subpowers image "..." --refs me` (ref sets for you, a product line, a brand kit, a fictional world)
- [ ] **World sheets**: a small text file per world (palette, style anchors, recurring characters) that is added to every prompt that uses it
- [ ] **Studio page**: a local web page to browse every image with its receipt, compare painters side by side, and re-run a winner with one click
- [ ] **Batch mode**: one prompt file, many images, both painters, a contact sheet at the end

## Later: more powers

- [ ] **Second opinion / copy**: ask the ChatGPT or Gemini model inside your plan for a draft or a critique, with the same receipt habit
- [ ] **Video**: the moment a subscription CLI exposes video generation, it becomes a painter here
- [ ] **Windows and Linux**: replace the macOS-only `sips` steps with a portable resize, and test the installer on both
- [ ] **More painters**: any subscription that ships an official CLI with a built-in image tool

## Won't do

- API keys or paid per-call fallbacks. The whole point is the plan you already have.
- Anything that shares one person's login with another person.
