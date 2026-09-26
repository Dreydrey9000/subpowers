---
name: subpowers
description: Use when the user or a workflow needs any generated image (picture, mockup, logo, avatar, thumbnail, hero image, illustration, product shot, concept art, a person or product placed in a new scene from reference photos, a character sheet, a storyboard), when a design, carousel, deck or video skill needs a picture, or when a picture would explain something better than text. Runs on the user's own ChatGPT, Google AI or SuperGrok subscription through their logged-in CLIs, no API key.
---

# subpowers

Most agents cannot paint. subpowers hands the job to the image models inside subscriptions the user already pays for: ChatGPT (through the `codex` CLI), Google Antigravity (through the `agy` CLI) and Grok Imagine (through the `grok` CLI). No API key, no per-image bill, and a receipt beside every image.

If `subpowers` is not on PATH, run `bash ~/.claude/skills/subpowers/bin/subpowers ...` (same arguments). Set the command timeout to 600000 ms, or run it in the background.

## Commands

```bash
subpowers image "<prompt>" /abs/out.png [--painter chatgpt|antigravity|grok|all] [--size WxH] [--ref photo.jpg]... [--refs NAME]
subpowers refs add NAME photo1.jpg photo2.heic ...     # save a reference set once (a person, a product, a world)
subpowers sheet NAME /abs/sheet.png [--painter all]     # character sheet: front, profiles, 3/4, back, face close-up
subpowers storyboard shots.txt /abs/outdir [--refs NAME] [--painter P] [--style "..."]   # one frame per line + a board
subpowers powers      # which subscriptions are connected right now
subpowers doctor      # live-checks every painter and names the exact fix
```

- stdout is the saved path (for `all`: one path per painter, then the side-by-side sheet). Beside each image: `out.prompt.txt` (prompt, the prompt the model received, model, C2PA signer, timings) and `out.original.*` when resized or converted.
- Look at every image before you show, describe or build on it. Then open it or send it to the user.
- **Offer choices when it matters:** one version (auto), three versions (`--painter all`, one per subscription), or different angles (a `sheet`, or several prompts).

## Pick the painter

| | `chatgpt` (default when connected) | `antigravity` | `grok` |
|---|---|---|---|
| Model | OpenAI's current image model | Google's Nano Banana 2 | xAI's Grok Imagine |
| Speed | 60 to 100 s | 17 to 40 s | 32 to 46 s |
| Best at | text in images, precise product fidelity | fast drafts, likeness from references, photoreal | bold stylized looks, a third opinion |
| Sizes | 1024x1024, 1536x1024, 1024x1536 exact; near shapes resized | 1:1, 2:3, 3:2, 3:4, 4:3, 9:16, 16:9 | 1:1, 16:9, 9:16, 3:2, 2:3 |
| References | any number | up to 3 (extra ones dropped) | yes (image edit) |
| Needs | `codex login` with ChatGPT | `agy` signed in once | SuperGrok + `grok login` |

`auto` uses the first connected painter and, if it fails (a paused plan, spent quota, a logged-out CLI), moves to the next one. A cancelled subscription never breaks anything: that painter just shows OFF in `subpowers powers` and is skipped.

## References and real people

- `--ref` / `--refs NAME` keep a person's face (their own photos), a product, or a style. Strong resemblance, not an identity lock. iPhone HEIC works on macOS.
- **Never pass a photo of a different real person as a "setting" reference.** The painters borrow faces from every reference (tested: Grok blended the user with the podcast host in the setting photo). Describe the set, pose, outfit and light in words instead, or crop the other person out first.
- Real proof stays real. Screenshots with numbers, logos, headlines and real faces are never regenerated from scratch: generate only the surround (background, mockup, scene) and composite the real pixels in; discard any output where a number, word or logo changed.

## Prompts that work

- Style anchor first ("isometric 3D render", "35mm photo"), then subject, composition, lighting, lens, materials, mood.
- End with "no text, no letters" unless words are the point. Put real text on afterwards in code.
- Never name a model inside the prompt.

## Storyboards

Write the shot list yourself (one shot per line: framing, action, setting), save it to a text file, then run `storyboard`. Frames paint in parallel (3 at a time, `SUBPOWERS_PARALLEL`), and `storyboard.jpg` shows them in order. Use `--refs NAME` so the same person appears in every shot, and `--style` for one consistent look. Antigravity is the fastest painter for boards.

## Video (not in this door yet)

No painter makes video headlessly today. Grok Imagine video (image to video, 6 or 10 s) works through the Grok CLI once its video output bucket is configured (or `/privacy` is off); Google's Gemini Omni needs the Gemini app. If the user needs a clip now, say so and name those routes; never fake a video from stills.

## Always the newest model

- Painters are chosen server-side by OpenAI, Google and xAI on every call, so they cannot go stale.
- The ChatGPT helper model comes from codex's own per-account model list, newest first; codex updates itself daily (`SUBPOWERS_NO_AUTOUPDATE=1` opts out). Antigravity uses the newest Gemini Flash in `agy models`; Grok the newest non-fast model in `grok models`.

## Errors

| Message | Fix |
|---|---|
| `no painter is connected` | `subpowers doctor` lists what to install and log in |
| `not logged in with ChatGPT` / `live check ... rejected` | `codex logout && codex login` |
| `agy returned no models` | run `agy` once in a terminal and sign in |
| `grok is not logged in` / exit 4 `SuperGrok feature` | `grok login` with a grok.com account that has SuperGrok |
| `dry (quota)` | that plan's usage is spent; `auto` already moves to the next painter |
| `no image_gen output` / `no generate_image output` / `never called image_gen` | the helper skipped the tool; rerun, or reword a prompt that reads like a policy refusal |
| `WARNING ... aspect` / `UPSCALED` | not an error: the receipt says exactly what was cropped or enlarged |
| `no reference set 'NAME'` | `subpowers refs add NAME photo1.jpg ...` |

## Files

- `bin/subpowers`: the front door. `bin/chatgpt-image`, `bin/antigravity-image`, `bin/grok-image`: the painters (same contract, callable directly).
- `bin/doctor`, `bin/resolve-drivers`, `bin/update-codex`: health check, newest-model choice, codex freshness.
- Reference sets live in `$SUBPOWERS_HOME/refs/NAME/` (default `~/.subpowers`).
- `install.sh`, `README.md`, `ROADMAP.md`, `CONTRIBUTING.md`.
