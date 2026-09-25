---
name: subpowers
description: Use when the user or a workflow needs any generated image (picture, mockup, logo, avatar, thumbnail, hero image, illustration, product shot, concept art, a person or product placed in a new scene from reference photos), when a design, carousel, deck or video skill needs a picture, or when a picture would explain something better than text. Runs on the user's own ChatGPT or Google AI subscription through their logged-in CLIs, no API key.
---

# subpowers

Most agents cannot paint. subpowers hands the job to the image models inside subscriptions the user already pays for: ChatGPT (through the `codex` CLI) and Google Antigravity (through the `agy` CLI). No API key, no per-image bill, and a receipt beside every image.

## Make an image

```bash
subpowers image "<prompt>" /abs/path/out.png [--painter chatgpt|antigravity] [--size WxH] [--ref photo.jpg]...
```

If `subpowers` is not on PATH, run `bash ~/.claude/skills/subpowers/bin/subpowers ...` (same arguments).

- Set the command timeout to 600000 ms, or run it in the background.
- Missing output folders are created. stdout is the saved path. Beside it: `out.prompt.txt` (your prompt, the prompt the model received, the model, the C2PA signer, timings) and `out.original.*` when the file was resized or converted.
- Look at the image before you show, describe or build on it. Then open it or send it to the user.
- Run `subpowers powers` to see which painters are connected, `subpowers doctor` when anything fails.

## Pick the painter

| | `chatgpt` (default when connected) | `antigravity` |
|---|---|---|
| Model | OpenAI's current image model, chosen by OpenAI | Google's Nano Banana 2, chosen by Google |
| Speed | 60 to 100 s | 17 to 25 s |
| Best at | text in images, precise edits, product fidelity | fast drafts, many variations, photoreal scenes |
| Sizes | 1024x1024, 1536x1024, 1024x1536 exact | 1:1, 2:3, 3:2, 3:4, 4:3, 9:16, 16:9 (1K) |
| References | any number | up to 3 |
| Needs | `codex login` with ChatGPT | `agy` signed in once |

Other shapes (16:9 on ChatGPT, 4:5 on Antigravity) are requested and then cropped or resized locally; the receipt and a WARNING say exactly what happened.

## Prompts that work

- Style anchor first ("isometric 3D render", "35mm photo"), then subject, composition, lighting, lens, materials, mood.
- End with "no text, no letters" unless words are the point. Put real text on afterwards in code.
- Never name a model inside the prompt.

## Reference images and real proof

`--ref` keeps a real person's face (their own photos), a product, or a style frame. png, jpg, webp; iPhone heic is converted on macOS. Strong resemblance, not an identity lock.

Real proof stays real. Screenshots with numbers (revenue, dashboards, receipts), logos, headlines and real people's faces are never regenerated from scratch: pass the real asset as `--ref` and change only the surround (background, mockup, lighting, scene), then compare the result against the original and discard it if any number, word or logo changed.

## Always the newest model

- Painters are chosen server-side by OpenAI and Google on every call, so they cannot go stale.
- The ChatGPT helper model is read fresh from codex's own per-account model list, newest first; codex updates itself once a day (opt out: `SUBPOWERS_NO_AUTOUPDATE=1`).
- The Antigravity helper model is the newest Gemini Flash that `agy models` lists.

## Not for

- Tiny programmatic images (solid colors, charts, placeholders): write them in code.
- Pixel edits to an existing file: use PIL, ffmpeg or an editor. A new image FROM a reference is fine.

## Errors

| Message | Fix |
|---|---|
| `no painter is connected` | `subpowers doctor` lists what to install and log in |
| `codex CLI not found` | `npm install -g @openai/codex` (or `brew install codex`) |
| `not logged in with ChatGPT` | `codex login`, choose Sign in with ChatGPT |
| `agy returned no models` | run `agy` once in a terminal and sign in |
| `dry (quota)` on every helper model | the plan's usage is spent; it resets on its own, or switch `--painter` |
| `no image_gen output` / `no generate_image output` | the helper skipped the tool; rerun, or reword a prompt that reads like a policy refusal |
| `WARNING ... aspect` | not an error: the painter made its nearest shape; the receipt says what was cropped |
| exit 75 (antigravity) | an optional capacity lease is busy; retry |

## Files

- `bin/subpowers`: the front door. `bin/chatgpt-image` and `bin/antigravity-image`: the painters (same contract, callable directly).
- `bin/doctor`, `bin/resolve-drivers`, `bin/update-codex`: health check, newest-model choice, codex freshness.
- `install.sh`, `README.md`, `ROADMAP.md`, `CONTRIBUTING.md`.
