#!/usr/bin/env bash
# The org's system toolchain, for a new sandbox. Remote only.
#
# Runs once inside the sandbox, serially, before the per-repo jobs: the only safe place for
# system installs, which would race each other from the parallel post-create hooks. It only
# installs and never starts a service, because a cached image skips it: waiting on docker
# and starting things belong to `dev`. Safe to run again.
#
# Env in: CS_STACK_REPOS (csv), CS_REMOTE_CODESPACE=1. The repos are still being cloned while
# this runs, so it decides by their names; files in them may not be there yet.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

lib="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib"
workspace="${CS_SANDBOX_WORKSPACE:-/codespace}"
repos=",${CS_STACK_REPOS:-},"
has_repo() { case "$repos" in *,"$1",*) return 0 ;; *) return 1 ;; esac; }

>&2 echo "==> org bootstrap: CS_STACK_REPOS=${CS_STACK_REPOS:-}"

if ! command -v apt-get >/dev/null 2>&1; then
	>&2 echo "err: remote-bootstrap: this org's sandboxes are Debian or Ubuntu; no apt-get here"
	exit 1
fi
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends ca-certificates curl git make

# python + uv (backend): uv is the one pyproject.toml pins, and it fetches the python that
# .python-version names by itself. A checkout not there yet falls back to today's pin;
# backend/post-create checks it again for the branch it runs on.
if has_repo backend; then
	# shellcheck source=lib/uv-pin.sh
	source "$lib/uv-pin.sh"
	pin="$(sample_co_uv_pinned "$workspace/backend/pyproject.toml")"
	sample_co_uv_ensure "${pin:-0.13.6}"
	uv --version
fi

# node + pnpm (frontend): any node 22 or later serves, so an image's newer one is left alone.
# Activating pnpm here, serially, keeps the parallel installs from racing corepack's download.
if has_repo frontend; then
	major="$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/')" || major=""
	if [ "${major:-0}" -lt 22 ]; then
		curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
		sudo apt-get install -y --no-install-recommends nodejs
	fi
	sudo corepack enable
	corepack prepare pnpm@10.34.9 --activate
	node --version
	pnpm --version

	# pnpm's store on the home volume, which outlives a stack, or each one downloads it all
	# again. /etc/environment because hooks over ssh take their environment from PAM.
	store="$HOME/.local/share/pnpm/store"
	mkdir -p "$store"
	grep -q '^NPM_CONFIG_STORE_DIR=' /etc/environment 2>/dev/null \
		|| printf 'NPM_CONFIG_STORE_DIR=%s\n' "$store" | sudo tee -a /etc/environment >/dev/null
fi
