#!/usr/bin/env bash
# tests/run.sh: every painter and the front door end to end, against stand-in CLIs.
#
# Nothing real is called and no plan is spent: tests/stubs/{codex,agy,grok} replay what the
# real CLIs print and write real image files. Everything runs on a minimal PATH of symlinks
# with no sips and no timeout, like stock Linux (and stock macOS for timeout).
#
#   bash tests/run.sh                              sips hidden
#   SUBPOWERS_TEST_SIPS=1 bash tests/run.sh        the host's sips on that PATH too (macOS)
#   SUBPOWERS_TEST_NO_PILLOW=1 bash tests/run.sh   Pillow hidden from every python3 it starts
#
# Exit 0 when every check passes.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bin="$repo/bin"; stubs="$repo/tests/stubs"
# Physical path: install.sh compares HOME against `pwd -P`.
T="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/subpowers-test.XXXXXX")" && pwd -P)"
trap 'rm -rf "$T"' EXIT
export PYTHONDONTWRITEBYTECODE=1

tools="bash sh env python3 perl cat cp mv rm ln mkdir mktemp dirname basename readlink date grep sed awk tr wc head tail ls find sort touch chmod sleep tar uname cut"
mkpath() {  # mkpath DIR [stub...]: symlinks to the basic tools plus the named stand-in CLIs
  local d="$1" t p; shift; mkdir -p "$d"
  for t in $tools; do p="$(type -P "$t" 2>/dev/null)" && ln -sf "$p" "$d/$t"; done
  for t in "$@"; do ln -sf "$stubs/$t" "$d/$t"; done
}
mkpath "$T/path" codex agy grok curl
if [[ -n "${SUBPOWERS_TEST_SIPS:-}" ]] && p="$(type -P sips)"; then ln -sf "$p" "$T/path/sips"; fi
mkpath "$T/path-nosips" codex agy grok curl
mkpath "$T/path-noclis"
mkdir -p "$T/nopil/PIL"
echo 'raise ImportError("Pillow hidden by tests/run.sh")' >"$T/nopil/PIL/__init__.py"
for d in path path-nosips path-noclis; do
  if [[ -e "$T/$d/sips" && "$d" != path ]] || [[ -e "$T/$d/timeout" ]]; then echo "setup: sips or timeout leaked into $d" >&2; exit 2; fi
done

pass=0; fail=0; failed=""; n=0; cur=""; rc=0; took=0
P="$T/path"; PYP=""
[[ -n "${SUBPOWERS_TEST_NO_PILLOW:-}" ]] && PYP="$T/nopil"

newcase() {  # newcase NAME: a fresh HOME, TMPDIR and stub logs
  cur="$1"; n=$((n+1)); C="$T/case$n"
  mkdir -p "$C/home" "$C/tmp" "$C/out"
  : >"$C/stub.log"; : >"$C/paints"
  echo "$cur"
}
run() {  # run [VAR=value...] CMD...: CMD in the case sandbox, bounded to $BOUND s; sets rc, took, $C/stdout, $C/stderr
  local t0; t0=$(date +%s)
  ( perl -e 'alarm shift; exec @ARGV' "${BOUND:-60}" \
      env -i HOME="$C/home" PATH="$P" TMPDIR="$C/tmp" STUB_LOG="$C/stub.log" STUB_PAINTS="$C/paints" \
        SUBPOWERS_NO_AUTOUPDATE=1 PYTHONDONTWRITEBYTECODE=1 ${PYP:+PYTHONPATH=$PYP} "$@" \
      >"$C/stdout" 2>"$C/stderr" </dev/null; exit $? ) 2>/dev/null   # a second command keeps the kill notice in here
  rc=$?; took=$(( $(date +%s) - t0 ))
}
ok()  { pass=$((pass+1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail+1)); failed="${failed}  ${cur}: $1
"; printf '  FAIL  %s\n' "$1"; }
check() { local what="$1"; shift; if "$@"; then ok "$what"; else bad "$what"; fi; }
exits() { [[ "$rc" == "$1" ]] || { echo "        exit $rc; stderr tail:"; tail -n 3 "$C/stderr" | cut -c1-160 | sed 's/^/          /'; return 1; }; }
has() { grep -qsE -- "$2" "$1"; }
hasnt() { [[ -f "$1" ]] && ! grep -qE -- "$2" "$1"; }
paints() {  # paints N [cli]: the stand-in CLIs painted exactly N images (of that CLI)
  local got; got="$(grep -c -- "${2:-.}" "$C/paints")"
  [[ "$got" == "$1" ]] || { echo "        painted $got times"; return 1; }
}
img() {  # img PATH FORMAT WxH
  local got; got="$(python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); import fakeimg
f, w, h = fakeimg.dims(sys.argv[2]); print("%s %dx%d" % (f, w, h))' "$stubs" "$1" 2>/dev/null || echo missing)"
  [[ "$got" == "$2 $3" ]] || { echo "        $(basename "$1") is $got"; return 1; }
}
printed() { [[ "$(tail -n 1 "$C/stdout")" == "$1" ]] || { echo "        printed: $(tail -n 1 "$C/stdout")"; return 1; }; }
called() { local m; m="$(grep -F -- "$1" "$C/stub.log")"; grep -qF -- "$2" <<<"$m"; }   # called <a stub call matching> <that also has>
pillow() { env -i HOME="$T" PATH="$P" ${PYP:+PYTHONPATH=$PYP} python3 -c 'import PIL' 2>/dev/null; }   # as the cases see it: no user site-packages

# Image ops exist when Pillow imports or sips is on the PATH. Without them a painter
# delivers its own file, in its own format and size, and says so.
OPS=""; { [[ -e "$P/sips" ]] || pillow; } && OPS=1
echo "== painters (sips $([[ -e "$P/sips" ]] && echo present || echo hidden), Pillow $(pillow && echo present || echo hidden))"

newcase "chatgpt: text to png at an asked size"
run bash "$bin/chatgpt-image" "a red mug" "$C/out/mug.png" --size 1024x1024
check "exit 0" exits 0
check "prints the image path" printed "$C/out/mug.png"
if [[ -n "$OPS" ]]; then check "png 1024x1024" img "$C/out/mug.png" png 1024x1024
else check "png at the painter's 1254x1254" img "$C/out/mug.png" png 1254x1254; fi
check "receipt" test -f "$C/out/mug.prompt.txt"
check "one paint" paints 1 codex
check "receipt carries token usage" has "$C/out/mug.prompt.txt" "tokens: input=25000 output=120$"

newcase "chatgpt: a helper that burns 200k input tokens is flagged"
run STUB_CODEX_INPUT_TOKENS=200000 bash "$bin/chatgpt-image" "a red mug" "$C/out/mug.png"
check "exit 0" exits 0
check "warns on stderr" has "$C/stderr" "the helper did more than paint"

newcase "antigravity: text to png at an asked size"
run bash "$bin/antigravity-image" "a red mug" "$C/out/mug.png" --size 1024x1024
check "exit 0" exits 0
if [[ -n "$OPS" ]]; then
  check "prints the image path" printed "$C/out/mug.png"
  check "png 1024x1024" img "$C/out/mug.png" png 1024x1024
else
  check "prints the delivered jpg" printed "$C/out/mug.jpg"
  check "jpeg 1024x1024" img "$C/out/mug.jpg" jpeg 1024x1024
fi
check "receipt" test -f "$C/out/mug.prompt.txt"
check "one paint" paints 1 agy

newcase "antigravity: 16:9 jpg cropped and resized to 1600x900"
run bash "$bin/antigravity-image" "a harbor at dawn" "$C/out/harbor.jpg" --size 1600x900
check "exit 0" exits 0
check "prints the image path" printed "$C/out/harbor.jpg"
if [[ -n "$OPS" ]]; then check "jpeg 1600x900" img "$C/out/harbor.jpg" jpeg 1600x900
else check "jpeg at the painter's 1376x768" img "$C/out/harbor.jpg" jpeg 1376x768; fi
check "receipt" test -f "$C/out/harbor.prompt.txt"
check "one paint" paints 1 agy

newcase "grok: text only, png at 1920x1080"
run bash "$bin/grok-image" "a fox on a rooftop" "$C/out/fox.png" --size 1920x1080
check "exit 0" exits 0
if [[ -n "$OPS" ]]; then
  check "prints the image path" printed "$C/out/fox.png"
  check "png 1920x1080" img "$C/out/fox.png" png 1920x1080
else
  check "prints the delivered jpg" printed "$C/out/fox.jpg"
  check "jpeg at the painter's 1376x768" img "$C/out/fox.jpg" jpeg 1376x768
fi
check "receipt" test -f "$C/out/fox.prompt.txt"
check "one paint" paints 1 grok
check "receipt labels the Imagine model as requested" has "$C/out/fox.prompt.txt" "^  image model requested: grok-imagine-image-quality"
check "receipt claims no answering model" hasnt "$C/out/fox.prompt.txt" "^  image model:"

newcase "grok: --ref edits into a 4:3 png"
python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); import fakeimg; fakeimg.png(sys.argv[2], 800, 600)' "$stubs" "$C/ref.png"
run bash "$bin/grok-image" "the same product on a beach" "$C/out/beach.png" --size 1024x768 --ref "$C/ref.png"
check "exit 0" exits 0
if [[ -n "$OPS" ]]; then check "png 1024x768" img "$C/out/beach.png" png 1024x768
else check "jpeg at the painter's 1184x864" img "$C/out/beach.jpg" jpeg 1184x864; fi
check "receipt" test -f "$C/out/beach.prompt.txt"
check "one paint" paints 1 grok
check "image_edit got the reference" called '"grok-paint"' '"tool": "image_edit", "aspect": "4:3", "images": 1'

newcase "front door: auto paints once"
run bash "$bin/subpowers" image "a red mug" "$C/out/mug.png"
check "exit 0" exits 0
check "one paint in total" paints 1

echo "== a paint that cannot be delivered"
for p in chatgpt antigravity grok; do
  newcase "$p: delivery fails after the paint"
  mkdir -p "$C/out/x.prompt.txt"   # the receipt cannot be written
  run bash "$bin/$p-image" "a red mug" "$C/out/x.png"
  check "exit 5" exits 5
  check "one paint" paints 1
done
newcase "front door: exit 5 is final, no second paint on another plan"
mkdir -p "$C/out/x.prompt.txt"
run bash "$bin/subpowers" image "a red mug" "$C/out/x.png"
check "exit 5" exits 5
check "one paint in total" paints 1

echo "== no image ops (no Pillow, no sips)"
P="$T/path-nosips"; PYP="$T/nopil"

newcase "antigravity: delivers its own jpg when asked for png"
run bash "$bin/antigravity-image" "a red mug" "$C/out/mug.png" --size 1024x1024
check "exit 0" exits 0
check "prints the delivered jpg" printed "$C/out/mug.jpg"
check "jpeg 1024x1024" img "$C/out/mug.jpg" jpeg 1024x1024
check "no mislabeled png" test ! -e "$C/out/mug.png"
check "warns on stderr" has "$C/stderr" "WARNING"
check "receipt says why" has "$C/out/mug.prompt.txt" "image ops"
check "one paint" paints 1 agy

newcase "grok: delivers its own jpg when asked for png"
run bash "$bin/grok-image" "a fox on a rooftop" "$C/out/fox.png"
check "exit 0" exits 0
check "prints the delivered jpg" printed "$C/out/fox.jpg"
check "jpeg 1024x1024" img "$C/out/fox.jpg" jpeg 1024x1024
check "receipt says why" has "$C/out/fox.prompt.txt" "image ops"
check "one paint" paints 1 grok

newcase "chatgpt: keeps the painter's size"
run bash "$bin/chatgpt-image" "a red mug" "$C/out/mug.png" --size 1024x1024
check "exit 0" exits 0
check "png 1254x1254" img "$C/out/mug.png" png 1254x1254
check "receipt says why" has "$C/out/mug.prompt.txt" "NOT resized.*image ops"
check "one paint" paints 1 codex

newcase "front door: indexes the file it delivered"
run bash "$bin/subpowers" image "a red mug" "$C/out/mug.png" --painter antigravity
check "exit 0" exits 0
check "prints the delivered jpg" printed "$C/out/mug.jpg"
run python3 "$bin/library" find --json
check "library holds the jpg" has "$C/stdout" 'mug\.jpg'

newcase "storyboard: counts shots delivered as jpg"
printf 'a fox wakes up\na fox finds a scarf\n' >"$C/shots.txt"
run bash "$bin/subpowers" storyboard "$C/shots.txt" "$C/out/board" --painter grok
check "exit 0" exits 0
check "2 of 2 shots" has "$C/stderr" "2 of 2 shots painted"
check "says the sheet needs Pillow" has "$C/stderr" "no side-by-side sheet.*Pillow"

newcase "council: says why there is no side-by-side sheet"
run bash "$bin/subpowers" image "a red mug" "$C/out/mug.png" --painter council
check "exit 0" exits 0
check "three paints" paints 3
check "says the sheet needs Pillow" has "$C/stderr" "no side-by-side sheet.*Pillow"

newcase "doctor: names what needs Pillow"
run bash "$bin/doctor"
check "exit 0 (painters are ready)" exits 0
check "WARN line names the Pillow features and the install" has "$C/stdout" "WARN .*Pillow.*council.*slideshow.*pip install"

P="$T/path"; PYP=""; [[ -n "${SUBPOWERS_TEST_NO_PILLOW:-}" ]] && PYP="$T/nopil"

echo "== no timeout(1) on PATH"
newcase "grok: GROK_IMAGE_TIMEOUT still ends a call that never answers"
BOUND=20 run STUB_GROK_HANG=25 GROK_IMAGE_TIMEOUT=2 bash "$bin/grok-image" "a fox" "$C/out/fox.jpg"
check "exit 1" exits 1
check "says it timed out" has "$C/stderr" "timed out"
check "within 12 s (took ${took}s)" test "$took" -lt 12

echo "== CLIs that keep talking after the answer (SIGPIPE under pipefail)"
newcase "powers: every logged-in plan is ON"
run STUB_CHATTY=1 bash "$bin/subpowers" powers
check "chatgpt ON" has "$C/stdout" "chatgpt +ON"
check "antigravity ON" has "$C/stdout" "antigravity +ON"
check "grok ON" has "$C/stdout" "grok +ON"
newcase "chatgpt: paints, isolated with --ignore-user-config"
run STUB_CHATTY=1 bash "$bin/chatgpt-image" "a red mug" "$C/out/mug.png"
check "exit 0" exits 0
check "--ignore-user-config passed" called '"exec"' '"--ignore-user-config"'
newcase "grok: paints"
run STUB_CHATTY=1 bash "$bin/grok-image" "a fox" "$C/out/fox.jpg"
check "exit 0" exits 0
newcase "doctor: sees the ChatGPT login"
run STUB_CHATTY=1 bash "$bin/doctor"
check "login PASS" has "$C/stdout" "PASS +login stored: ChatGPT"

echo "== doctor drives the same car as the painters"
newcase "doctor: live check isolated like chatgpt-image"
run bash "$bin/doctor"
check "exit 0" exits 0
for flag in 'model_provider=\"openai\"' 'openai_base_url=' 'mcp_servers={}' 'project_doc_max_bytes=0' 'features.shell_tool=false' '--ignore-user-config'; do
  check "pong call has $flag" called 'Reply with exactly: pong' "$flag"
done
check "antigravity helper is the painter's default (high)" has "$C/stdout" "helper model: gemini-[0-9.]+-flash-high"
newcase "doctor: reads ~/.subpowers/config"
mkdir -p "$C/home/.subpowers"
printf 'CHATGPT_IMAGE_DRIVERS=gpt-test-sol:default\nAGY_IMAGE_EFFORT=low\n' >"$C/home/.subpowers/config"
run bash "$bin/doctor"
check "pong call pinned to the configured helper" called 'Reply with exactly: pong' '"-m", "gpt-test-sol"'
check "reports the configured ChatGPT helper" has "$C/stdout" "gpt-test-sol"
check "reports the configured antigravity helper" has "$C/stdout" "helper model: gemini-[0-9.]+-flash-low"
newcase "doctor: a dry first helper falls through, like the painter"
mkdir -p "$C/home/.subpowers"
printf 'CHATGPT_IMAGE_DRIVERS=gpt-test-sol:default\n' >"$C/home/.subpowers/config"
run STUB_CODEX_DRY_MODEL=gpt-test-sol bash "$bin/doctor"
check "live check PASS on the next helper" has "$C/stdout" "PASS +live check"
newcase "chatgpt: a dry first helper falls through to the next, one paint"
run STUB_CODEX_DRY_MODEL=gpt-test-sol CHATGPT_IMAGE_DRIVERS=gpt-test-sol:default bash "$bin/chatgpt-image" "a red mug" "$C/out/mug.png"
check "exit 0" exits 0
check "one paint" paints 1 codex
check "receipt names the helper that painted" has "$C/out/mug.prompt.txt" "driver model: default"
newcase "doctor: a spent quota is not a login problem"
run STUB_CODEX_LIVE_ERROR="You've hit your usage limit. Try again in 3 hours." bash "$bin/doctor"
check "names the quota" has "$C/stdout" "FAIL .*(quota|usage limit)"
check "no logout advice" hasnt "$C/stdout" "codex logout"
newcase "doctor: a network failure is named as one"
run STUB_CODEX_LIVE_ERROR="error sending request for url (https://chatgpt.com/backend-api/codex/responses)" bash "$bin/doctor"
check "names the network" has "$C/stdout" "FAIL .*network"
check "no logout advice" hasnt "$C/stdout" "codex logout"
newcase "doctor: an auth failure keeps the login advice"
run STUB_CODEX_LIVE_ERROR="unexpected status 401 Unauthorized" bash "$bin/doctor"
check "logout and login" has "$C/stdout" "FAIL .*codex logout && codex login"

echo "== codex daily update"
newcase "update-codex: a report does not stamp the daily check"
stamp="$C/home/.cache/subpowers/codex-update-check"
run STUB_NPM_VERSION=0.158.0 bash "$bin/doctor"
check "doctor leaves no stamp" test ! -e "$stamp"
run STUB_NPM_VERSION=0.158.0 bash "$bin/update-codex"
check "report exits 1 (behind)" exits 1
check "report leaves no stamp" test ! -e "$stamp"
run STUB_NPM_VERSION=0.158.0 bash "$bin/update-codex" --daily --apply
check "apply exits 0" exits 0
check "apply ran codex update" called '"codex"' '["update"]'
check "apply stamps" test -e "$stamp"

echo "== install and help"
newcase "install: a fresh machine with no CLIs"
P="$T/path-noclis"
run bash "$repo/install.sh"
check "exit 0" exits 0
check "its next steps name all three logins" has "$C/stdout" "Grok: +grok login"
P="$T/path"
newcase "help: prints the header only"
run bash "$bin/subpowers" help
check "exit 0" exits 0
check "usage text" has "$C/stderr" "Usage:"
check "no code in the help" hasnt "$C/stderr" "set -euo"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]] && exit 0
printf 'failed:\n%s' "$failed"
exit 1
