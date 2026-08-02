# Claude Code Desktop Setup — New Collaborator Onboarding

This checklist ensures a clean, safe, and learning-optimized Claude Code environment on Mac Neo.

---

## Step 0: Get This Repo

If you're reading this on GitHub, clone it so you have the docs locally:

```bash
git clone https://github.com/Mikebabin/onboarding-claude-code.git
cd onboarding-claude-code
```

(Repo URL may differ — use whatever link Mike sent you.)

---

## Pre-Setup (Machine Requirements)

Run these in Terminal before opening Claude Code:

```bash
# 1. Verify Homebrew is installed and at /opt/homebrew
which brew
# Expected: /opt/homebrew/bin/brew

# 2. Install jq (required by hooks)
brew install jq

# 3. Verify Node.js and npm version
node -v  # should be v18+
npm -v   # must be >= 11.10.0 for min-release-age support

# If npm is too old, upgrade:
npm install -g npm@latest
```

**If any of these fail,** stop and let me know the output. The hooks won't work safely without them.

---

## Step 1: Clone the Project Repository

This is the repo you'll actually work in (Mike will give you the name — it's a different repo from this onboarding one):

```bash
git clone https://github.com/Mikebabin/<project-repo>.git
cd <project-repo>
```

The `.claude/` directory in the project repo is already configured with the safety hooks. You don't need to create or copy anything — the onboarding repo you cloned in Step 0 is just documentation and reference copies.

---

## Step 2: Install Claude Desktop + Claude Code

1. Download **Claude Desktop** from https://claude.ai/download
2. Install to Applications
3. Launch it from Applications (not Terminal — this is how it'll normally run)
4. When it opens, click the **Code** tab at the bottom

Claude Code will activate on first launch. This takes ~30 seconds.

---

## Step 3: Install Superpowers Plugin (One Time)

In a Claude Code session, run these commands in order:

```
/plugin marketplace add obra/superpowers-marketplace
```

Wait for confirmation. Then:

```
/plugin install superpowers@superpowers-marketplace
```

Type `/plugins` to verify it shows as installed and active. You only do this once.

---

## Step 4: Verify the Safety Hooks Are Active

Type `/hooks` in Claude Code. You should see three `Project` hooks:

- `PreToolUse` → `npm-guard.sh`
- `PreToolUse` → `secret-scan.sh`
- `SessionStart` → `unicode-scan.sh`

All should have source `Project`, not `User`. If you see `User` hooks or they're missing, stop and ask me.

---

## Step 5: Test Each Hook (Critical)

These deliberately trigger the guards to confirm they work:

**Test 1: npm-guard blocks risky npm verbs**

```
npm install some-random-package --install-option="--build-from-source"
```

Expected: Claude Code blocks it with a clear reason. You see a denial in the transcript.

**Test 2: unicode-scan fires at SessionStart**

Start a new Claude Code session (File > New Session). Look for a `unicode-scan.sh` hook output in the transcript. It should show a scan result or a quiet exit.

**Test 3: secret-scan blocks .env reads**

Ask Claude Code to "read the .env file". Expected: blocked with a reason.

If all three block as expected, the layer is active and working. If you see `hook error` notices instead of actual blocks, the PATH issue (#1 from earlier) is present — tell me and we'll fix it.

---

## Step 6: Configure for Learning (Not Full Strength)

Open `.claude/settings.json` in your editor. Find the `permissions` block (near the top).

Change this:

```json
"permissions": {
  "default": "default"
}
```

To this:

```json
"permissions": {
  "default": "plan"
}
```

Save. Restart Claude Code.

**What this does:** You now see a permission dialog before Claude runs *every* tool call. You approve each one. This is slower but teaches you what Claude is doing at each step — exactly what you need while learning. Once you're confident, you can change back to `"default": "auto"`.

---

## Step 7: GitHub SSH Setup (Optional but Recommended)

When Claude Code needs to push code:

```bash
gh auth login
# Choose HTTPS
# Authenticate via browser
```

Claude Code will use your cached credentials. No SSH key juggling needed.

---

## First Session: Test Run

1. Open Claude Code (from Applications, via the Desktop icon, or the Code tab)
2. Open your project folder (File > Open Folder, pick the repo you cloned)
3. Ask Claude something simple: `"Summarize the README"`
4. Watch the `/hooks` output and the permission dialogs
5. Approve a tool call and see it run

If everything works, you're done.

---

## Troubleshooting

### Hooks show as `User` instead of `Project`
You may have accidentally edited `~/.claude/settings.json`. The project hooks in `.claude/settings.json` should take precedence. Verify the file exists:
```bash
ls -la .claude/settings.json
```
If it's there, restart Claude Code. If it's not, tell me.

### `hook error: jq not found`
Homebrew's `jq` isn't on the PATH when Claude Code launches from the GUI. Run:
```bash
brew install jq
```
Then restart Claude Desktop completely (not just the session).

### npm blocks everything, even normal installs
This is expected at first. The guards are strict. When you hit a legitimate need, ask me before disabling anything — there's usually a sanctioned path (like `npm run build` for build scripts).

### `min-release-age` not working
Verify npm version again:
```bash
npm -v
```
Must be ≥ 11.10.0. If it's older, `min-release-age=3` silently doesn't apply.

---

## What's Actually Happening

**Committed to the repo (`.claude/` directory):**
- `.claude/settings.json` — hook wiring + safety rules
- `.claude/hooks/*.sh` — three shell scripts that guard against risky operations
- `.npmrc` — npm security settings (ignore build scripts, exact versions, minimum age)

**You install once (not in the repo):**
- Claude Desktop (GUI launcher)
- Superpowers plugin (development skills)

**The hooks do:**
- **npm-guard**: blocks risky npm verbs like `--build-from-source`, `--unsafe-perm`
- **secret-scan**: blocks reads of `.env` and other sensitive files
- **unicode-scan**: scans for hidden Unicode tricks at session start (extremely rare but severe)

**The learning config:**
- Permission mode set to `plan` so you see and approve every tool call
- Superpowers plugin loaded so Claude knows TDD, debugging, code review workflows

All three hooks are intentionally strict to teach good practices. As you get comfortable, we can relax specific things.

---

## You're Ready When

- [ ] Homebrew, jq, Node, npm all installed and verified
- [ ] Repository cloned
- [ ] Claude Desktop running
- [ ] Superpowers installed (`/plugins` shows it)
- [ ] `/hooks` shows three Project hooks
- [ ] All three hooks tested and blocking as expected
- [ ] Permission mode set to `plan`
- [ ] First session ran without errors

If anything is unclear or fails, paste the exact error and I'll walk you through it.
