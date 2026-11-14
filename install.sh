#!/usr/bin/env bash
# gbtop installer
#   curl -fsSL https://raw.githubusercontent.com/t3n9r1/gbtop/main/install.sh | bash
#
# Optional environment variables:
#   GBTOP_PREFIX   install directory (default: /usr/local/bin, or ~/.local/bin without sudo)
#   GBTOP_REF      branch or tag to install (default: main)
set -euo pipefail

REPO="t3n9r1/gbtop"
REF="${GBTOP_REF:-main}"
URL="${GBTOP_URL:-https://raw.githubusercontent.com/${REPO}/${REF}/gbtop}"

say()  { printf '\033[1;36mgbtop\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mgbtop\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Linux" ] || fail "gbtop only runs on Linux."
command -v python3 >/dev/null 2>&1 || fail "python3 not found. Install it first (sudo apt install python3)."
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' \
  || fail "python3 is too old: gbtop needs Python 3.8 or newer."
python3 -c 'import curses' 2>/dev/null || fail "Python module 'curses' is missing (sudo apt install libpython3-stdlib)."

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
say "downloading ${URL}"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$tmp" || fail "download failed."
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "$URL" || fail "download failed."
else
  fail "neither curl nor wget found."
fi
head -n 1 "$tmp" | grep -q '^#!.*python3' || fail "downloaded file is not gbtop (wrong URL or private repository?)."
python3 -m py_compile "$tmp" 2>/dev/null || fail "downloaded file is damaged."
find "$(dirname "$tmp")" -maxdepth 2 -name "$(basename "$tmp")*.pyc" -delete 2>/dev/null || true

if [ -n "${GBTOP_PREFIX:-}" ]; then
  dir="$GBTOP_PREFIX"; mkdir -p "$dir"; install -m 755 "$tmp" "$dir/gbtop"
elif [ -w /usr/local/bin ]; then
  dir=/usr/local/bin; install -m 755 "$tmp" "$dir/gbtop"
elif command -v sudo >/dev/null 2>&1 && sudo -v 2>/dev/null; then
  dir=/usr/local/bin; sudo install -m 755 "$tmp" "$dir/gbtop"
else
  dir="$HOME/.local/bin"; mkdir -p "$dir"; install -m 755 "$tmp" "$dir/gbtop"
fi

say "installed $("$dir/gbtop" --version 2>/dev/null | sed 's/^/version /') to $dir/gbtop"
case ":$PATH:" in
  *":$dir:"*) say "start it with: gbtop" ;;
  *) say "$dir is not in your PATH. Add it (export PATH=\"$dir:\$PATH\") or run $dir/gbtop" ;;
esac
