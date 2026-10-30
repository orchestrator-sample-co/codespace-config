# codespace-config (sample-co)

A working org config for [codespace](https://orchestrator.cloud/codespace), for a made-up company. Copy it to start your own org's.

It runs two small sample apps in a stack, [backend](https://github.com/orchestrator-sample-co/backend) (a notes API on FastAPI and Postgres, with a worker) and [frontend](https://github.com/orchestrator-sample-co/frontend) (a Vite web app), and it uses every part of the config a real product needs. Hooks say why they exist in their headers. The contract behind them is `codespace prompt sandbox-bootstrap`.

## Setup

1. Install the `codespace` CLI.
2. Run setup, with `--projects-dir` set to where you keep this org's repos:

```sh
codespace config setup github.com/orchestrator-sample-co --projects-dir ~/sample-co
```

That installs this config at `~/codespace-config/sample-co` and checks out your personal branch, `user/<github-login>`.

3. Make a stack and run it:

```sh
cd ~/sample-co
codespace stack create my-feature
cd stack_my-feature    # the path create printed
codespace dev -r
```

`codespace dev -r` names anything still missing: your backend `.env` (`cp .env.example .env` in `~/sample-co/backend`), and your identity, which it offers to set up.

## Personal vs shared

| Branch | What belongs here |
|---|---|
| `main` | Shared hooks: `config.json`, the bootstraps, `<repo>/` hooks |
| `user/<you>` | Your overlays: `AGENTS.md`, `TODO.md`, `backend/AGENTS.md`, `frontend/AGENTS.md`. The default checkout after setup |

`user/<you>` is `main` plus your own commits on top, never merged with it. `codespace config setup` creates it from `main`, commits nothing on it, and pushes it to this repo (`--no-push` leaves it local), so you need write access here. Every re-run brings it onto the latest `main`: a fast-forward while it has no commits of its own, otherwise your commits rebased on top.

Day to day, stay on your personal branch. For an org-wide change:

```sh
git checkout main
git checkout -b improve-something
# edit shared hooks, open a PR into main
# once it lands: git checkout user/<you> && git rebase main
```

## Caching and scope

Three scopes. What goes wrong is nearly always something in the wrong one.

| scope | what sample-co puts there | must not contain |
|---|---|---|
| **per-org** (the cached database volume) | the migrated, empty Postgres, through `config.json` `.cache` and `backend/dev`'s `cache arm --wait` | the seeded dev user, or anyone's tokens: this is why the seed runs after `--wait` returns |
| **per-user** (the sandbox's `$HOME`) | the pnpm store (`remote-bootstrap.sh`), the deps-cache of `node_modules` (`frontend/post-create`), `~/.config/sample-co/dev-identity` (`backend/mirrored-files`) | anything with a stack's own absolute path, which is why `.venv` is stamped and not cached |
| **per-stack** | `.codespace/ready-auth`, values from `dev env-set`, the local stack's compose project | nothing meant to be shared |

## Layout

| Path | What it does | Runs |
|---|---|---|
| `config.json` | The stacks and their settings, below | |
| `remote-bootstrap.sh` | System toolchain of a new sandbox | sandbox, once |
| `local-bootstrap.sh` | Laptop toolchain, for `codespace doctor --fix` | laptop, when asked |
| `stack-post-create.sh` | Personal overlays at the stack's root | both |
| `test-prepare` | The weights of a `codespace test` run | laptop |
| `onboard-notes` | What `codespace onboard` adds under a new colleague's setup sheet. `{name}`, `{org}` and `{projects_dir}` are filled in | |
| `lib/` | Helpers the hooks source | |
| `backend/post-create`, `frontend/post-create` | Install dependencies | both |
| `backend/patch-configs`, `frontend/patch-configs` | Point each service at this stack, before it starts | both |
| `backend/dev`, `frontend/dev` | Run the services | both |
| `frontend/ready`, `frontend/ready-env` | The deep check: add a note as the dev user | laptop |
| `backend/test`, `frontend/test` | The suites `unit`, `integration`, `web` | test sandbox |
| `backend/dev-reset` | Takes away the seeded database (`codespace env rm`) | where dev ran |
| `backend/pre-delete` | Removes this stack's database volume (`codespace rm`) | where dev ran |
| `backend/mirrored-files`, `backend/setup-identity` | Host-level files for the sandbox, and the script that makes the required one | laptop |
| `backend/env-withhold`, `backend/env-prod-markers` | Keys kept out of a sandbox; values `codespace audit` flags | laptop |

## config.json, key by key

JSON has no comments, so here it is.

| Key | What it says |
|---|---|
| `version` | The config format. |
| `org` | The cnc org this config belongs to: it names where sandboxes run and who pays. See below. |
| `dev.probe_timeout` | Seconds `codespace dev` waits on listeners and `ready` before it warns and carries on. |
| `dev.ports` | Label to port, forwarded at once. A label becomes `$CS_DEV_URL_<LABEL>`. `{ "port", "scheme" }` sets the scheme; a bare number is the default one. |
| `dev.preview` | The labels `dev -r -p` shares, with one public link each. |
| `sandbox` | A stack's sandbox size. `swap` and `disk` are read too, when you need them. |
| `cache` | The volume snapshot: `repo` and `compose` say which database, `paths` which files make a snapshot stale, and `warm` which branch to keep warm how often. |
| `test.sandbox` | The size of a `codespace test` slot. |
| `test.default` | The suites of a bare `codespace test`. |
| `test.timeout`, `test.stall` | Seconds until a run, or a run with no output, is ended. |
| `clean.protect`, `clean.reclaim` | What `codespace clean` keeps, and what it may delete, in a removed checkout. |
| `stacks` | Presets for `codespace stack create -s <name>`. `default` is the array form, just repos. `api-only` is the object form, with its own smaller `sandbox`. |

## GitHub org vs cnc org

They are two different names, and they need not match:

| Name | Value here | Used in |
|---|---|---|
| GitHub org | `orchestrator-sample-co` | `cloneURL`s, `codespace config setup github.com/...` |
| cnc org | `sample-co` | `config.json` `org` |

This repo is found by convention: `codespace config setup github.com/<org>` looks for `<org>/codespace-config`.

## Start your org from this

1. Copy this repo to `<your-github-org>/codespace-config`.
2. In `config.json`, set `org` to your cnc org, the `cloneURL`s to your repos, and `dev.ports` to your services.
3. Rename `backend/` and `frontend/` after your repos. A hook directory's name is the repo's name.
4. Replace `make ...` and `pnpm ...` in the hooks with your repos' own commands. The hooks should call your repo's commands and hold no project logic of their own.
5. Replace `sample_co`, `sample-co` and `sample-co.example` throughout: `grep -rn sample . | grep -v README`.
6. Rewrite `frontend/ready` so it exercises your own main feature. A check that only sees a port listening proves little.
7. Rewrite `onboard-notes` for your own env files.

## Not shown here

Documented, but not needed by this config (see `codespace prompt sandbox-bootstrap`):

- `mixedProjects` and the `defaults` map in `config.json`.
- `dev machine`: a whole host as a dev unit.
- A stack-level `test.sh`, which replaces the per-repo test hooks.
- A per-repo `remote-bootstrap.sh`.
- `codespace hide`, to git-exclude a provisioning artifact.
- `dev.class`.

## Left out on purpose

Other org configs may carry `clean-orphans`, `<repo>/clean-outside` or `<repo>/.git-info-exclude`. No client reads them today, so nothing here pretends otherwise.
