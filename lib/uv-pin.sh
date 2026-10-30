#!/usr/bin/env bash
# The uv the backend pins, and installing it. Sourced by both bootstraps and by
# backend/post-create; defines only.

# The uv a pyproject.toml pins, or nothing. Args: pyproject.toml
sample_co_uv_pinned() {
	[ -r "$1" ] || return 0
	awk -F'"' '/^required-version = "==/ { sub(/^==/, "", $2); print $2; exit }' "$1"
}

# Install this version of uv into ~/.local/bin unless it is what PATH has. uv refuses to run
# at any other version than the pin, so a package manager's newer one will not do.
# Args: version
sample_co_uv_ensure() {
	local want="$1" have
	[ -n "$want" ] || return 0
	have="$(uv --version 2>/dev/null | awk '{ print $2; exit }')" || have=""
	[ "$have" != "$want" ] || return 0
	>&2 echo "==> uv ${have:-absent} -> $want"
	mkdir -p "$HOME/.local/bin"
	curl -fsSL "https://astral.sh/uv/$want/install.sh" \
		| UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh >&2
}
