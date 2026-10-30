#!/usr/bin/env bash
# Wires the stack as a whole, once, after its repos are in place. Local and remote.
# Env in: STACK_ROOT. Each line is a personal overlay from your user/<login> branch of this
# repo, absent on main: a missing source warns and carries on, so a create never fails here.
set -euo pipefail

codespace stack-post-create.link-files-from-config AGENTS.md
codespace stack-post-create.link-alias AGENTS.md CLAUDE.md
codespace stack-post-create.copy-files-from-config TODO.md
