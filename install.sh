#!/usr/bin/env bash
# install.sh: give every agent on this machine the subpowers skill.
#
#   bash install.sh                  install for this user ($HOME)
#   bash install.sh --dest DIR       install under DIR instead of $HOME (dry run for testing)
#   bash install.sh --no-doctor      skip the health check at the end
#
# What it does:
#   1. puts the skill at ~/.claude/skills/subpowers (Claude Code reads it there).
#      Cloned there already? It stays a git checkout, so `subpowers update` works.
#   2. links it into ~/.agents/skills and ~/.codex/skills (Codex, Cursor, Gemini CLI, others)
#   3. puts `subpowers`, `chatgpt-image` and `antigravity-image` on PATH via ~/.local/bin
#   4. installs the codex CLI if it is missing and npm or Homebrew is available
#   5. runs `subpowers doctor`
#
# Safe to re-run. Anything it replaces is moved to ~/.claude/backups/, never deleted.
# It never logs you in: run `codex login` (ChatGPT) and/or `agy` (Antigravity) yourself.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
root="$HOME"; doctor=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) [[ $# -ge 2 ]] || { echo "usage: bash install.sh [--dest DIR] [--no-doctor]" >&2; exit 2; }; root="$2"; shift 2 ;;
    --no-doctor) doctor=""; shift ;;
    *) echo "usage: bash install.sh [--dest DIR] [--no-doctor]" >&2; exit 2 ;;
  esac
done
mkdir -p "$root"; root="$(cd "$root" && pwd -P)"

ts="$(date +%Y%m%d-%H%M%S)"
target="$root/.claude/skills/subpowers"
backups="$root/.claude/backups/subpowers-$ts"

stash() {  # move an existing path aside, outside every skills folder
  mkdir -p "$backups"
  mv "$1" "$backups/$2"
  echo "  moved old $1 -> $backups/$2"
}

echo "subpowers install -> $root"

# 1. the skill itself
mkdir -p "$(dirname "$target")"
if [[ "$here" != "$(cd "$(dirname "$target")" && pwd -P)/subpowers" ]]; then
  if [[ -e "$target" || -L "$target" ]]; then stash "$target" "skill"; fi
  mkdir -p "$target"
  (cd "$here" && tar --exclude='.git' --exclude='__pycache__' --exclude='*.bak-*' --exclude='.DS_Store' -cf - .) \
    | (cd "$target" && tar -xf -)
  echo "  copied skill -> $target"
else
  echo "  running from $target (git checkout: $([[ -d "$target/.git" ]] && echo yes || echo no))"
fi
chmod +x "$target"/bin/* "$target"/install.sh 2>/dev/null || true

# 2. other agents' skill folders
link_into() {  # link_into <skills-dir>
  local d="$1/subpowers"
  mkdir -p "$1"
  if [[ -L "$d" ]]; then ln -sfn "$target" "$d"
  else
    if [[ -e "$d" ]]; then stash "$d" "$(basename "$(dirname "$1")")-skills-copy"; fi
    ln -s "$target" "$d"
  fi
  echo "  linked $d"
}
link_into "$root/.agents/skills"
link_into "$root/.codex/skills"

# 3. terminal commands
mkdir -p "$root/.local/bin"
for c in subpowers chatgpt-image antigravity-image; do
  ln -sfn "$target/bin/$c" "$root/.local/bin/$c"
done
echo "  linked subpowers, chatgpt-image, antigravity-image into $root/.local/bin"
case ":$PATH:" in *":$root/.local/bin:"*) ;; *)
  if [[ "$root" == "$HOME" ]]; then echo "  NOTE: add ~/.local/bin to your PATH to type subpowers anywhere (agents do not need this)"; fi ;;
esac

# 4. codex CLI (the ChatGPT painter's engine)
if [[ "$root" == "$HOME" ]] && ! command -v codex >/dev/null 2>&1; then
  if command -v npm >/dev/null 2>&1; then echo "  installing codex: npm install -g @openai/codex"; npm install -g @openai/codex || echo "  codex install failed; install it yourself: npm install -g @openai/codex"
  elif command -v brew >/dev/null 2>&1; then echo "  installing codex: brew install codex"; brew install codex || echo "  codex install failed; install it yourself: brew install codex"
  else echo "  codex not installed (needs Node.js or Homebrew). Only needed for the ChatGPT painter."; fi
fi

# 5. health check
echo
if [[ "$root" != "$HOME" ]]; then
  echo "(--dest install: skipped codex install and doctor)"
elif [[ -n "$doctor" ]]; then
  bash "$target/bin/doctor" || {
    echo
    echo "Next: log in to at least one subscription, then run: subpowers doctor"
    echo "  ChatGPT:     codex login   (choose Sign in with ChatGPT)"
    echo "  Antigravity: agy           (sign in once, then quit)"
    exit 1
  }
fi
