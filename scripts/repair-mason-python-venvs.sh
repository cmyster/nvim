#!/usr/bin/env bash
# Repair Mason-installed Python tool venvs whose interpreter went missing.
#
# Background: Mason installs Python-based tools (cpplint, etc.) as a venv under
# ~/.local/share/nvim/mason/packages/<tool>/venv. The venv shebang hardcodes the
# Python interpreter path. On Gentoo, a python-exec slot switch (e.g. 3.13 to 3.14)
# removes /usr/lib/python-exec/python3.X/python3, breaking every such venv with
# "ENOENT: no such file or directory". nvim-lint surfaces this on :w as
#   Error running cpplint: ENOENT: no such file or directory
#
# This script finds broken venvs and rebuilds them in place against the current
# python3, reinstalling the package using the Mason package directory name as
# the pip package name. That convention holds for the tools in this config; if
# Mason ever installs a Python tool whose pip name differs, rebuild that one by
# hand and add a mapping below.

set -euo pipefail

MASON_DIR="${MASON_DIR:-$HOME/.local/share/nvim/mason/packages}"

if [[ ! -d "$MASON_DIR" ]]; then
  echo "Mason packages dir not found: $MASON_DIR" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not on PATH; cannot rebuild venvs" >&2
  exit 1
fi

repaired=0
checked=0

for pkg_dir in "$MASON_DIR"/*/; do
  venv="${pkg_dir}venv"
  py="${venv}/bin/python"
  [[ -e "$py" ]] || continue
  checked=$((checked + 1))

  # readlink -e resolves symlinks and returns nonzero if any link in the chain
  # is dangling — that is exactly the "interpreter is gone" condition.
  if readlink -e "$py" >/dev/null 2>&1; then
    continue
  fi

  pkg="$(basename "${pkg_dir%/}")"
  echo "broken venv: $pkg (interpreter missing) — rebuilding"

  rm -rf "$venv"
  python3 -m venv "$venv"
  "${venv}/bin/pip" install --quiet --upgrade pip
  "${venv}/bin/pip" install --quiet "$pkg"
  echo "  reinstalled $pkg"
  repaired=$((repaired + 1))
done

echo "checked $checked Python venv(s); repaired $repaired"
