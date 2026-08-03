# Claude Code Desktop Setup — New Collaborator Onboarding

This checklist takes you from a fresh Mac to a working, safety-hardened Claude Code environment. Each step says **what happens** and **why it matters** — you should never be typing something you don't understand.

Budget ~30–45 minutes. If any step fails, stop and send Mike the exact output — don't improvise around it.

---

## Step 0: Get This Repo

**What:** Clone the onboarding repo so you have these docs locally.
**Why:** You'll want the checklist and reference files next to you while you work, and Claude can read them too.

```bash
git clone https://github.com/Mikebabin/onboarding-claude-code.git
cd onboarding-claude-code
```

(Repo URL may differ — use whatever link Mike sent you.)

> **If this errors with `xcode-select: note: no developer tools were found`** (or a dialog pops up offering to install tools): that's normal on a fresh Mac. `git` isn't actually installed yet — macOS ships a stub that offers to install the **Xcode Command Line Tools** the first time you use it. Run:
>
> ```bash
> xcode-select --install
> ```
>
> Click **Install** in the dialog (takes ~5 minutes; no Apple ID needed — it's the command-line tools, not full Xcode). Then re-run the `git clone`.

---

## Step 1: Machine Prerequisites

**What:** Verify Homebrew, install `jq`, verify Node and npm versions.
**Why:** The safety hooks are shell scripts that parse JSON — they need `jq` (or `node` as a fallback) to read what Claude is about to do. And one of the npm protections (`min-release-age`) only exists in newer npm; on older versions it's *silently ignored*, which is worse than an error.

Run these in Terminal:

```bash
# 1. Verify Homebrew is installed and at /opt/homebrew
which brew
# Expected: /opt/homebrew/bin/brew

# 2. Install jq (the hooks use it to parse Claude's tool calls)
brew install jq

# 3. Verify Node.js and npm versions
node -v  # should be v18+
npm -v   # must be >= 11.10.0 — older versions silently ignore min-release-age
```

**If `which brew` prints nothing,** Homebrew isn't installed. Install it yourself, in Terminal, using the command on the front page of https://brew.sh (it also installs the Xcode Command Line Tools if Step 0 didn't already). One important habit note: that install command is a `curl | bash` — the exact pattern the safety hooks *block Claude from running*. That's not a contradiction: the rule is that piping the internet straight into a shell is only acceptable when a human deliberately does it from a trusted source, never when an AI agent does it mid-task. So run it by hand, don't ask Claude to.

**If `node` isn't found,** install it after Homebrew: `brew install node`.

If npm is too old:

```bash
npm install -g npm@latest
```

**If any of these fail,** stop and send Mike the output. The hooks won't work safely without them.

---

## Step 2: Clone the Project Repository

**What:** Clone the repo you'll actually work in (Mike will give you the name — it's a different repo from this onboarding one).
**Why:** The safety configuration lives *inside the project repo* — a committed `.claude/` directory with the hooks and settings, plus a hardened `.npmrc`. Cloning it is what installs the safety layer; there's nothing to copy or configure by hand.

```bash
git clone https://github.com/Mikebabin/<project-repo>.git
cd <project-repo>
```

The onboarding repo from Step 0 is just documentation and reference copies.

---

## Step 3: Install Claude Desktop + Claude Code

**What:** Install the app you'll be working in.
**Why:** Claude Code is the agent; everything else in this checklist exists to make it safe and productive.

1. Download **Claude Desktop** from https://claude.ai/download
2. Install to Applications
3. Launch it from Applications (not Terminal — this is how it'll normally run, and it matters: the hooks are written to survive the different environment a Dock-launched app gets)
4. When it opens, click the **Code** tab at the bottom

Claude Code activates on first launch. Takes ~30 seconds.

**Two things to keep straight:**

- **Claude Desktop is two products in one window.** The regular chat tab is ordinary Claude — it has *none* of the safety layer in this checklist. Everything here (hooks, plan mode, npm hardening) exists only inside **Claude Code** sessions, i.e. the Code tab. Do project work in the Code tab, not the chat tab.
- **The desktop app isn't the only way in.** The `claude` CLI in Terminal and the VS Code/JetBrains extensions are the same engine — they read the same project `.claude/` directory and the same per-machine config, so the guards fire identically in all of them. This checklist assumes the desktop app because it's the easiest start; switch surfaces later without redoing anything. (One exception: web sessions at claude.ai/code run in a cloud environment — the project's committed hooks still apply there, but machine-level pieces like the Superpowers plugin don't follow. Stick to your Mac while onboarding.)

---

## Step 4: Install the Superpowers Plugin (One Time)

**What:** Add a plugin that gives Claude structured development skills.
**Why:** Out of the box, Claude Code will happily jump straight to writing code. Superpowers teaches it disciplined workflows — brainstorm before building, test-driven development, systematic debugging, code review. You'll see it announce "Using [skill]..." in sessions; that's this.

In a Claude Code session, run:

```
/plugin install superpowers@claude-plugins-official
```

This installs from Anthropic's official plugin marketplace (built in — no `/plugin marketplace add` step needed). Verify with `/plugins` — it should show as installed and active. You only do this once; it applies to all projects.

> **Note:** Older versions of this guide installed from the third-party `obra/superpowers-marketplace`. Use the official marketplace instead — same plugin, first-party source. If you already installed the obra copy, disable it in `/plugins` so you don't have two.

### How much process to use (token efficiency)

Superpowers includes two ways to execute an implementation plan, and they differ a lot in cost:

- **Inline (default):** Claude executes the plan itself in one session, then runs a single code review at the end. Use this for small plans — up to ~4–5 tasks, tightly coupled changes, or work in one subsystem. One shared context means files are read once and cached; this is the token-efficient path, and current models (Opus/Fable) hold enough context to do it well.
- **Subagent-driven development (SDD):** Claude dispatches a fresh implementer *and* reviewer agent per task, plus a final whole-branch review. Each agent re-reads everything from scratch, so a 6-task plan can spawn 15–20 fresh contexts. Reserve it for large plans (6+ independent tasks) or risky work where independent per-task review is the point.

Either way, keep the end-of-branch review — it's the cheap part of the process that catches most of what review catches.

---

## Step 5: Verify the Safety Hooks Are Active

**What:** Confirm the project's hooks are registered.
**Why:** A hook that isn't registered protects nothing. This is the moment you confirm the safety layer is actually on.

Open the project folder in Claude Code (File > Open Folder), then type `/hooks`. You should see **four registrations, all with source `Project`**:

| Event | Matcher | Hook |
|-------|---------|------|
| `PreToolUse` | `Bash` | `npm-guard.sh` |
| `PreToolUse` | `Bash` | `secret-scan.sh` |
| `PreToolUse` | `Read\|Edit\|Write` | `secret-scan.sh` |
| `SessionStart` | — | `unicode-scan.sh` |

(secret-scan appears twice on purpose: once screening terminal commands, once screening direct file access — two doors into the same secrets.)

If any are missing, or show source `User` instead of `Project`, stop and ask Mike.

---

## Step 6: Test Each Hook (Critical)

**What:** Deliberately trip each guard once.
**Why:** You need to see what a block looks like *before* you hit one for real — so when it happens mid-task, you recognize it as the system working, not breaking. And an untested guard is an assumed guard.

**Test 1: npm-guard blocks risky npm commands**

Ask Claude to run:

```
npm install -g cowsay
```

Expected: blocked, with a message explaining that global installs are disallowed and to install into the project with a pinned version instead.

**Test 2: secret-scan blocks credential reads**

Ask Claude to "read the .env file".

Expected: blocked, with a message saying it looks like a credential file. This fires whether Claude uses the terminal (`cat .env`) or its file-reading tool — that's why the hook is registered twice.

**Test 3: unicode-scan fires at session start**

Start a new session (File > New Session) in the project folder. In the transcript you should see the SessionStart hook run and report — normally "Unicode security scan: no suspicious patterns detected."

**If you see `hook error` notices instead of clean blocks,** that's usually the PATH/jq issue — see Troubleshooting, then tell Mike.

---

## Step 7: Understand Learning Mode (Already Configured)

**What:** The project ships with permission mode set to `plan` — nothing to edit; just understand what you're seeing.
**Why:** In plan mode, Claude proposes each action and waits for your approval before running it. It's slower, and that's the point: while you're learning, every dialog is a chance to see *what* Claude wants to do and *why*, before it happens. Nothing runs without you.

This is set in the project's `.claude/settings.json`:

```json
"permissions": {
  "defaultMode": "plan"
}
```

You'll see permission dialogs constantly at first. Read them — they're the curriculum.

Once you're comfortable (give it a week or two), talk to Mike about relaxing it. The usual next step is `"defaultMode": "acceptEdits"` (file edits auto-approved, commands still ask). Don't change this yourself yet.

---

## Step 8: GitHub Authentication

**What:** Log in to GitHub so Claude can push code.
**Why:** Claude uses your cached credentials for git operations — no tokens pasted into terminals (which the secret-scan hook would rightly block anyway).

```bash
gh auth login
# Choose HTTPS
# Authenticate via browser
```

---

## First Session: Test Run

**What:** One easy end-to-end session.
**Why:** Confirms the whole stack — app, plugin, hooks, permissions — works together before you start real work.

1. Open Claude Code from Applications (Dock/GUI, not Terminal)
2. Open your project folder (File > Open Folder)
3. Ask something simple: `"Summarize the README"`
4. Watch the SessionStart scan fire, then the permission dialogs
5. Approve a tool call and see it run

If that works, you're done.

---

## Troubleshooting

### `xcode-select: note: no developer tools were found`
You ran `git` (or another developer command) on a Mac that doesn't have the Xcode Command Line Tools yet. Run `xcode-select --install`, click **Install** in the dialog, wait ~5 minutes, then retry the command that failed. See Step 0.

### `xcode-select --install` says "Install requested" but nothing happens
The install dialog sometimes never appears — a known macOS flake. In order:

1. `xcode-select -p` — if it prints `/Library/Developer/CommandLineTools`, the tools are already installed; just retry your command.
2. The dialog may be hiding behind other windows or slow to appear; also check **System Settings → General → Software Update**.
3. Reboot, then run `xcode-select --install` again. This fixes it most of the time.
4. Still stuck: install without the GUI —
   ```bash
   sudo touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
   softwareupdate --list          # find the "Command Line Tools for Xcode-XX.X" label
   softwareupdate --install "Command Line Tools for Xcode-XX.X"   # label exactly as listed
   sudo rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
   ```
5. Last resort: download the Command Line Tools installer from https://developer.apple.com/download/all/ (free Apple ID required). Or just proceed to installing Homebrew (Step 1) — its installer can pull in the CLT itself.

### Hooks show as `User` instead of `Project`
Something in your home-directory `~/.claude/settings.json` is registering hooks. The project hooks should still work, but tell Mike — sources shouldn't be mixed during onboarding.
```bash
ls -la .claude/settings.json   # confirm the project file exists
```

### `hook error: jq not found`
Apps launched from the Dock don't get Homebrew's PATH. The hooks compensate for this internally, but only if `jq` is actually installed at `/opt/homebrew/bin`:
```bash
brew install jq
which jq   # expected: /opt/homebrew/bin/jq
```
Then fully quit Claude Desktop (⌘Q) and relaunch — a session restart isn't enough.

### npm blocks everything, even normal installs
Mostly expected — the guards are strict on purpose. Plain `npm install <package>` should pass; global installs, blanket updates, and script re-enabling won't. When a legitimate need hits a guard, ask Mike — there's usually a sanctioned path (e.g., `npm rebuild <package>` for native modules).

### `min-release-age` not working
```bash
npm -v
```
Must be ≥ 11.10.0. Older npm ignores the setting **silently** — no warning, no error, no protection.

---

## What's Actually Happening (The Full Picture)

**Committed to the project repo — you get these automatically by cloning:**
- `.claude/settings.json` — wires the hooks to Claude's actions + sets plan-mode permissions
- `.claude/hooks/*.sh` — the three guard scripts
- `.npmrc` — npm hardening: `ignore-scripts=true` (packages can't run code at install time), `save-exact=true` (no floating versions), `min-release-age=3` (no packages published in the last 3 days — poisoned releases are usually caught within days)

**You install once on your machine — not in any repo:**
- Claude Desktop (the app)
- `jq` via Homebrew (JSON parsing for the hooks)
- Superpowers plugin (development skills)

**The division of labor:**
- The **hooks** stop dangerous *actions* (risky installs, credential reads, hidden Unicode)
- The **.npmrc** stops dangerous *packages* (install-time scripts, brand-new releases)
- **Plan mode** keeps *you* in the loop on everything else

Everything is intentionally strict while you learn. As you get comfortable, specific things get relaxed deliberately — one at a time, with a reason, by asking. Never by working around a guard.

---

## You're Ready When

- [ ] Homebrew, jq, Node, npm all installed and verified (Step 1)
- [ ] Project repository cloned (Step 2)
- [ ] Claude Desktop running, launched from Applications (Step 3)
- [ ] Superpowers installed — `/plugins` shows it (Step 4)
- [ ] `/hooks` shows four `Project` registrations (Step 5)
- [ ] All three guards tested and firing as expected (Step 6)
- [ ] You've read what plan mode is and why it's on (Step 7)
- [ ] `gh auth login` done (Step 8)
- [ ] First session ran clean

If anything is unclear or fails, paste the exact error to Mike.
