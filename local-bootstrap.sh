#!/usr/bin/env bash
# The laptop's toolchain: the local twin of remote-bootstrap.sh.
#
# `codespace doctor --fix` runs it and nothing else does, so an install only happens when the
# developer asked for one. Cwd is this directory, stdin is closed, and it never prompts.
# What is already there at a good version is left alone. What it cannot install, it names
# with an instruction and a non-zero exit.
set -euo pipefail
export HOMEBREW_NO_ASK=1 COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin"

command -v brew >/dev/null 2>&1 || {
	>&2 echo "err: sample-co's laptop toolchain installs through Homebrew: https://brew.sh"
	exit 1
}

# node 22 or later (frontend/.nvmrc, its package.json's engines).
major="$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/')" || major=""
if [ "${major:-0}" -lt 22 ]; then
	>&2 echo "==> node ${major:-absent} -> 22"
	brew install node@22
	brew link --overwrite --force node@22
	hash -r
fi
node --version

# pnpm through corepack, into ~/.local/bin, which the installer put on PATH. A pnpm 9.7 or
# later already there is left alone: it runs the version package.json names by itself.
pnpm_ok() { pnpm --version 2>/dev/null | awk -F. '{ ok = $1 > 9 || ($1 == 9 && $2 >= 7) } END { exit !ok }'; }
if ! pnpm_ok; then
	>&2 echo "==> pnpm through corepack"
	corepack enable --install-directory "$HOME/.local/bin" pnpm
	corepack prepare pnpm@10.34.9 --activate
	hash -r
	pnpm_ok || {
		>&2 echo "err: pnpm through corepack does not run as 9.7 or later"
		exit 1
	}
fi
pnpm --version

# uv at backend's pin, through its own installer: brew has only the newest uv, and uv refuses
# to run at another version than the pin. It fetches the python .python-version names itself.
# shellcheck source=lib/uv-pin.sh
source "lib/uv-pin.sh"
sample_co_uv_ensure 0.13.6
uv --version

command -v docker >/dev/null 2>&1 || {
	>&2 echo "err: backend's database runs in docker: install Docker Desktop, then run codespace doctor --fix again"
	exit 1
}
