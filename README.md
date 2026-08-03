# Claude Code Onboarding — Mac Setup with Safety Hooks

Welcome. This repo takes you from a fresh Mac to a working, safety-hardened Claude Code environment — and explains *why* each piece exists, not just what to type.

## What is this, in plain English?

**Claude Code** is an AI coding agent. Unlike a chatbot, it doesn't just suggest code — it runs terminal commands, edits files, and installs packages on your machine. That's what makes it useful, and it's also why we don't run it bare.

This setup adds a **safety layer**: three small shell scripts ("hooks") that automatically check what Claude is about to do *before it does it*. If an action looks risky — installing a package globally, reading your credentials, running a script piped straight off the internet — the hook blocks it and tells Claude (and you) why.

You don't have to remember any rules. The guards are automatic, they're committed to the project repo, and they explain themselves when they fire.

## What you'll end up with

| Piece | What it is | Why you need it |
|-------|-----------|-----------------|
| Claude Desktop + Claude Code | The app you'll work in | It's the agent that writes and runs code with you |
| Homebrew, jq, Node | Command-line prerequisites | The hooks are shell scripts that parse JSON — they need `jq`/`node` to work |
| Three safety hooks | Scripts that screen Claude's actions | Blocks the most common ways an AI agent (or a malicious npm package) can do damage |
| `.npmrc` hardening | npm config in the project repo | Stops packages from running arbitrary code at install time |
| Plan-mode permissions | Claude asks before every action | While you're learning, you see and approve each step — nothing happens without you |
| Superpowers plugin | Development skills for Claude | Teaches Claude structured workflows: TDD, debugging, code review |

## The three guards, and why they exist

- **npm-guard** — screens every terminal command for risky package-manager patterns: global installs, blanket updates (`npm update`, `npm audit fix`), custom registries, re-enabling install scripts, and `curl | bash` pipe-to-shell. *Why:* the #1 real-world attack on developers today is a poisoned npm package; these patterns are how it gets in.
- **secret-scan** — blocks Claude from reading or touching credential files: `.env`, SSH keys, `.aws/` credentials, tokens. It screens both terminal commands and direct file reads/edits. *Why:* an AI agent should never need your secrets to write code, so any attempt to touch them is either a mistake or an attack — block first, ask questions after.
- **unicode-scan** — at the start of every session, scans project files for invisible Unicode characters (zero-width spaces, bi-directional overrides). *Why:* rare but nasty supply-chain trick — code that looks harmless on screen but reads differently to the compiler. This one warns rather than blocks.

**The one rule:** if a guard blocks something, it shows a reason. If the reason doesn't make sense, **ask Mike — don't disable the guard or work around it.** The guards are strict on purpose, and there's a sanctioned path for almost every legitimate need.

## Where the safety layer applies

Claude Code runs in several places, and they all share the same configuration — so the guards travel with you:

- **Identical protection:** the Claude Code desktop app (the Code tab in Claude Desktop), the `claude` CLI in a terminal, and the VS Code/JetBrains extensions. Same engine, same project `.claude/` directory, same hooks.
- **No protection:** the regular Claude *chat* tab (or claude.ai in a browser). That's a different product — hooks don't exist there. Do project work in Claude Code only.
- **Partial:** web sessions at claude.ai/code run in a cloud environment. The hooks committed to the project repo still apply (they're cloned with the code), but machine-level pieces — the Superpowers plugin, your personal settings — stay on your Mac.

## If you're the new collaborator: start here

1. Work through **[SETUP-CHECKLIST.md](./SETUP-CHECKLIST.md)** top to bottom. Every step says what it does and why. Budget ~30–45 minutes.
2. Then clone the **project repo** Mike gives you — the hooks are already committed there, so opening it in Claude Code activates everything automatically.
3. Stuck? Paste the exact error message to Mike. Don't disable anything to get unstuck.

## What's in this repo

| Path | What it is |
|------|-----------|
| `SETUP-CHECKLIST.md` | The onboarding walkthrough. The reason this repo exists. |
| `hooks/` | The three safety hook scripts (reference copies — canonical versions live in each project repo) |
| `claude-settings.json` | Template for a project's `.claude/settings.json` (hook wiring + plan-mode permissions) |
| `npmrc.template` | Template for a project's `.npmrc` (npm install hardening) |
| `docs/INTEGRATION.md` | For maintainers: how to add these hooks to a new project repo |

## For maintainers: setting up a new project

See [docs/INTEGRATION.md](./docs/INTEGRATION.md). Short version: copy `hooks/` into the project's `.claude/hooks/`, copy the two templates in as `.claude/settings.json` and `.npmrc`, `chmod +x` the scripts, commit.

Note: the hooks are written to run on the stock macOS shell (bash 3.2) — pattern matching happens in `perl`, which ships with macOS. Don't rewrite them with bash-4.x features; they'll silently misbehave on a default Mac.
