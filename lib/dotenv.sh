#!/usr/bin/env bash
# Reads the backend's env files the way the app does. Sourced by its hooks; defines only.

# The value of a key in the cwd's env files, in the app's precedence (.env.local over .env,
# as its settings load them). Fails when neither sets it. Prints to stdout: never let a
# hook echo the result of a key that may be a secret. Args: key
sample_co_env_get() {
	local key="$1" file line
	for file in .env.local .env; do
		line="$(grep -E "^[[:space:]]*(export[[:space:]]+)?${key}=" "$file" 2>/dev/null | tail -1 || true)"
		[ -n "$line" ] || continue
		line="${line#*=}"
		line="${line%\"}"
		line="${line#\"}"
		line="${line%\'}"
		line="${line#\'}"
		printf '%s' "$line"
		return 0
	done
	return 1
}
