#!/usr/bin/env sh
# Clovance uninstaller for Linux / macOS.
#
# Thin wrapper around install.sh's "uninstall" command so the documented
# one-liner works:
#
#   curl -fsSL https://evaristocuesta.github.io/clovance/install/uninstall.sh | sh
#
# It uses the install.sh sitting next to this file when running from a
# checkout, and downloads the published one otherwise.

set -eu

URL="https://evaristocuesta.github.io/clovance/install/install.sh"

# When this script is piped into a shell, stdin is the script itself, so the
# prompts in install.sh would read EOF and silently keep their defaults.
# Reattach the terminal for the child process only (never for this shell, which
# may still be reading the rest of this file from stdin).
DIR=""
case "$0" in
  */*) DIR=$(CDPATH='' cd -- "${0%/*}" && pwd) ;;
esac

DOWNLOADED=""
if [ -z "$DIR" ] || [ ! -f "$DIR/install.sh" ]; then
  # Not mktemp: GNU and BSD disagree on the template argument.
  DIR="${TMPDIR:-/tmp}/clovance-install.$$"
  mkdir -p "$DIR"
  echo "==> Downloading installer..."
  curl -fsSL "$URL" -o "$DIR/install.sh"
  DOWNLOADED=1
fi

cleanup() {
  if [ -n "$DOWNLOADED" ]; then rm -rf "$DIR"; fi
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# No "exec": the EXIT trap has to run to remove the downloaded copy.
if [ ! -t 0 ] && ( : </dev/tty ) 2>/dev/null; then
  sh "$DIR/install.sh" uninstall < /dev/tty
else
  sh "$DIR/install.sh" uninstall
fi
