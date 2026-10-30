#!/usr/bin/env bash
# The compose project of this stack's database. Sourced by backend's hooks; defines only.

# Stacks on one laptop share a docker engine, so each names its own project: its database
# volume stays its own, and removing the stack can remove exactly that volume.
# Named after the stack's root and not its slug: `dev` and `pre-delete` are told the same
# root, while a local stack's CS_DEV_SLUG and CS_DELETE_SLUG are not the same string.
# Args: the stack's root (CS_DEV_ROOT, CS_DELETE_ROOT)
sample_co_compose_project() {
	printf 'sample-co-%s' "$(basename "$1")" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]+/-/g'
}
