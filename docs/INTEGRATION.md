# Integrating Safety Hooks into Your Shared Repository

This document walks you through adding the three safety hooks and project settings to your repository so the new collaborator gets them automatically on clone.

---

## What You're Adding

**To the repo:**
- `.claude/hooks/npm-guard.sh` — blocks risky npm operations
- `.claude/hooks/secret-scan.sh` — blocks reads of `.env`, credentials, SSH keys
- `.claude/hooks/unicode-scan.sh` — detects hidden Unicode tricks at session start
- `.claude/settings.json` — hook wiring + learning-mode permission config
- `.npmrc` — npm security settings (exact versions, no build scripts, minimum age)

**Collaborator installs once:**
- Claude Desktop
- Superpowers plugin (via `/plugin` commands)

---

## Step 1: Create the .claude Directory Structure

```bash
mkdir -p .claude/hooks
```

---

## Step 2: Copy the Hook Scripts

Copy each script from this onboarding repo into `.claude/hooks/` in your repo:

```bash
cp hooks/npm-guard.sh <project>/.claude/hooks/npm-guard.sh
cp hooks/secret-scan.sh <project>/.claude/hooks/secret-scan.sh
cp hooks/unicode-scan.sh <project>/.claude/hooks/unicode-scan.sh
```

Make them executable:

```bash
chmod +x .claude/hooks/*.sh
```

Verify:

```bash
ls -la .claude/hooks/
# Should show three executable .sh files with the +x bit set
```

---

## Step 3: Copy the Settings File

The template is named `claude-settings.json` (no leading dot) so it stays visible in Finder and GitHub. Rename it on copy:

```bash
cp claude-settings.json <project>/.claude/settings.json
```

---

## Step 4: Copy the npm Config

The npm config is in `npmrc.template` because some setups already have `.npmrc`. Review what you have (if anything):

```bash
cat .npmrc 2>/dev/null || echo "No .npmrc present"
```

**If you have no `.npmrc`:**

```bash
cp npmrc.template <project>/.npmrc
```

**If you already have `.npmrc`:**

Open it, and add these lines if they're not already there:

```
ignore-scripts=true
save-exact=true
min-release-age=3
```

(The other lines in the template are helpful but optional.)

---

## Step 5: Commit and Push

```bash
git add .claude/
git add .npmrc
git commit -m "chore: add safety hooks and learning-mode Claude Code config"
git push origin main
```

---

## Step 6: Verify the Collaborator Can Use It

Have them run the onboarding checklist from `SETUP-CHECKLIST.md` (in the onboarding repo). The key verification steps are:

1. Clone the repo
2. Launch Claude Desktop, open the folder
3. Type `/hooks` — should show three `Project` hooks
4. Deliberately trigger each hook to confirm it blocks

If all three hooks show as `Project` and block as expected, they're ready to work.

---

## Troubleshooting for You

### "The scripts don't have the execute bit"

If you commit them without `chmod +x`, git won't preserve the executable bit. Fix:

```bash
chmod +x .claude/hooks/*.sh
git update-index --chmod=+x .claude/hooks/*.sh
git commit -m "fix: set executable bit on hook scripts"
```

### "The hooks show as User, not Project"

This means the collaborator has a `.claude/settings.json` in `~/.claude/` (their home directory) that's taking precedence. The project one is still there and works, but it's being masked. Have them clear their user-scope settings or use the workspace-trusted feature if available.

### "The hooks aren't running at all"

Most likely: `jq` isn't installed or isn't at `/opt/homebrew/bin/jq`. Have them run:

```bash
brew install jq
which jq
# Should print /opt/homebrew/bin/jq
```

If it's somewhere else (e.g., `/usr/local/bin/jq` from MacPorts), the hooks will fail. The scripts hardcode the path for the launchd PATH issue. You can either:
- Have them reinstall via Homebrew: `brew install jq` (overwrites)
- Edit the three scripts to use `$(command -v jq)` if you want flexibility (but this reverts to the PATH problem on GUI launch)

---

## What Each Hook Does (For Your Reference)

**npm-guard.sh:**
- Blocks `npm install --build-from-source` (compiles arbitrary code)
- Blocks `--unsafe-perm` (privilege escalation)
- Blocks global installs `-g`
- Blocks `npm audit fix` (can silently break things)
- Blocks `npm cache clean` and `npm config set` (affects other projects)

**secret-scan.sh:**
- Blocks Read/Edit/Write of `.env*` files
- Blocks `.aws/`, `.ssh/`, `.kube/`, credentials files, secret files, token files
- Blocks `.gpg` keys
- Warns rather than crashes if jq is missing (still blocks with a reason)

**unicode-scan.sh:**
- Scans the repo at session start for zero-width characters, Private Use Area Unicode, bi-directional overrides
- Reports findings to Claude as a warning, not a hard block
- Detects supply-chain attacks that use hidden Unicode to inject code

---

## Optional: Relaxing the Guards for Specific Cases

Once the collaborator is comfortable, if a legitimate use case hits a guard, you can:

1. **Temporarily disable all hooks:** In `.claude/settings.json`, add `"disableAllHooks": true` at the top level. They can also do this locally in `~/.claude/settings.json`, but tell them to undo it afterward.

2. **Whitelist a specific npm verb:** Edit `.claude/hooks/npm-guard.sh` and add an exception case. For example, if you use Husky (which needs post-install scripts):

   ```bash
   # Before the "Block: arbitrary script execution" comment, add:
   if echo "$COMMAND" | grep -qE 'npm install.*husky'; then
     exit 0
   fi
   ```

   Then commit the change so they get it too.

3. **Approve builds with `npm rebuild`:** Document in CLAUDE.md that native modules require `npm rebuild <package>` after a normal install. This is the sanctioned path and doesn't disable the guard.

---

## Next Steps

1. Do Steps 1–5 above in your repo
2. Give the collaborator `SETUP-CHECKLIST.md` (in the onboarding repo)
3. Have them follow it start-to-finish
4. Spot-check their first session: ask them to screenshot `/hooks` output

You're done when they can start a session, all three hooks show as `Project`, and they've deliberately triggered at least one to see the block message.
