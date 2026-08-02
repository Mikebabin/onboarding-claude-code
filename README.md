# Claude Code Onboarding — Mac Setup with Safety Hooks

Welcome. This repo gets you from a fresh Mac to a working, safety-hardened Claude Code environment.

## If you're the new collaborator: start here

1. **Follow [SETUP-CHECKLIST.md](./SETUP-CHECKLIST.md)** top to bottom. It covers:
   - Installing prerequisites (Homebrew, jq, Node)
   - Installing Claude Desktop + the Superpowers plugin
   - Verifying the safety hooks work on *your* machine
2. **Then clone the project repo** you'll actually be working in — it already has the hooks committed. When Claude Code opens it, everything in this checklist should already be active.
3. Stuck? Paste the exact error message to Mike. Don't disable anything to get unstuck — the guards are strict on purpose, and there's a sanctioned path for almost everything.

## What's in this repo

| Path | What it is |
|------|-----------|
| `SETUP-CHECKLIST.md` | The onboarding walkthrough. The reason this repo exists. |
| `hooks/` | The three safety hook scripts (reference copies — canonical versions live in each project repo) |
| `claude-settings.json` | Template for a project's `.claude/settings.json` |
| `npmrc.template` | Template for a project's `.npmrc` |
| `docs/INTEGRATION.md` | For maintainers: how to add these hooks to a new project repo |

## What the safety hooks do

- **npm-guard** — blocks risky npm operations (global installs, `--unsafe-perm`, `npm audit fix`, build-from-source)
- **secret-scan** — blocks Claude from reading `.env` files, SSH keys, cloud credentials, tokens
- **unicode-scan** — scans for hidden Unicode characters at session start (a rare but severe supply-chain attack vector)

They block with an explanation, not just a wall. If a block message doesn't make sense, ask — don't work around it.

## For maintainers: setting up a new project

See [docs/INTEGRATION.md](./docs/INTEGRATION.md). Short version: copy `hooks/` into the project's `.claude/hooks/`, copy the two templates in as `.claude/settings.json` and `.npmrc`, `chmod +x` the scripts, commit.
