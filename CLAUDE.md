# Claude Code CLI - Agent Context

**Core Repository Knowledge**: [AGENT.md](AGENT.md)

**User Preferences**: [USER_IDENTITY.md](USER_IDENTITY.md)

---

## Purpose

This file defines Claude Code-specific interaction patterns for the terminal-config repository. All architectural and technical knowledge resides in AGENT.md. This file addresses exclusively:
- Tool usage conventions
- Git workflow requirements
- Testing expectations
- File modification priorities
- Repository-specific guidelines

---

## Tool Usage Patterns

### File Modification Hierarchy

**Rule 1**: ALWAYS prefer Edit over Write.
- Why: Edit tool shows context, preserves formatting, safer for modifications
- Use Write ONLY for: Complete file replacement or new file creation
- Exception: None

**Rule 2**: ALWAYS Read before Edit.
- Why: Understand existing structure, avoid breaking changes, verify formatting
- Exception: Truly new files with zero dependencies

**Rule 3**: Use Glob for file discovery.
- Why: Fast, handles large codebases efficiently
- Example: `Glob: pattern="**/*.sh"` instead of `Bash: find . -name "*.sh"`

**Rule 4**: Use Grep for content search.
- Why: Optimized for code search, supports regex, respects .gitignore
- Example: `Grep: pattern="alias activate_ai"` instead of `Bash: grep -r`

### Task Management

**Rule 1**: Use TodoWrite for multi-step tasks.
- Threshold: 3+ distinct steps OR non-trivial complexity
- States: `pending`, `in_progress`, `completed`
- Constraint: EXACTLY ONE task `in_progress` at any time

**Rule 2**: Update task status in real-time.
- Mark `completed` IMMEDIATELY after finishing (no batching)
- Mark `in_progress` BEFORE starting work
- Remove irrelevant tasks (clean up stale tasks)

**Rule 3**: Task completion criteria.
- ONLY mark `completed` when FULLY accomplished
- If errors/blockers: keep `in_progress`, create new task for resolution
- Never mark `completed` if: tests failing, implementation partial, unresolved errors

### Plan Mode

**Enter Plan Mode When**:
1. User explicitly requests design/architecture work
2. Task requires exploration before implementation (e.g., "understand how X works")
3. Architectural decisions needed before coding
4. Multiple implementation approaches possible

**DO NOT Enter When**:
1. Clear, direct implementation request
2. Bug fixes with obvious solution
3. Documentation updates
4. Routine maintenance

---

## Git Workflow

### Commit Protocol

**Rule 1**: ONLY commit when user explicitly requests.
- Never proactively commit without user instruction
- Never commit as part of "finishing" a task unless requested

**Rule 2**: Commit message format.
- Structure: `<type>: <description>`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Examples:
  - `feat: Add NVM initialization to .zshrc`
  - `fix: Correct PATH order in .shell_common`
  - `docs: Update AGENT.md with version manager details`
- Always end with: `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`

**Rule 3**: Pre-commit analysis.
- Run `git status` to see untracked files
- Run `git diff` to see staged/unstaged changes
- Run `git log` to see recent commits
- Analyze changes, draft commit message
- Present draft to user for approval (unless user provided exact message)

**Rule 4**: HEREDOC format for commit messages.
- ALWAYS use HEREDOC for proper formatting
- Enables multi-line messages with proper escaping

### Git Safety Protocol

**Forbidden Actions** (NEVER execute):
- Update git config (e.g., `git config user.name`)
- Destructive operations: `git push --force`, `git reset --hard`
- Skip hooks: `--no-verify`, `--no-gpg-sign`
- Force push to main/master (warn user if requested)
- Interactive commands: `git rebase -i`, `git add -i`

**Conditional Actions** (ONLY if conditions met):
- `git commit --amend`:
  1. User explicitly requested amend, OR commit succeeded but hook auto-modified files
  2. HEAD commit created by you in this conversation (verify: `git log -1 --format='%an %ae'`)
  3. Commit NOT pushed to remote (verify: `git status` shows "Your branch is ahead")
- If commit FAILED or REJECTED by hook: NEVER amend, fix issue and create NEW commit

### Pull Request Workflow

**Preparation**:
1. Run in parallel:
   - `git status` (untracked files)
   - `git diff` (staged/unstaged changes)
   - Check if current branch tracks remote and is up-to-date
   - `git log [base-branch]...HEAD` (commits since branch diverged)
2. Analyze ALL commits that will be in PR (not just latest)
3. Draft PR summary

**Creation**:
- Use `gh pr create` with title and body
- Format: ## Summary, ## Test plan, 🤖 Claude Code attribution
- Create new branch if needed, push with `-u` flag
- Return PR URL to user

---

## Testing Expectations

**Rule 1**: Validate before marking tasks complete.
- For shell config changes: Test syntax with `zsh -n <file>` or `bash -n <file>`
- For deployment scripts: Test with dry-run or verify logic
- For documentation: Verify links, code blocks, formatting

**Rule 2**: Run validation script after deployment changes.
- Script: `bash_scripts_/deployment_validate.sh` or `deployment/validate.sh`
- Expected: All checks return `✓`, fail count = 0
- If fails: Fix issues before marking complete

**Rule 3**: Test version manager integration after PATH changes.
- Pyenv: `pyenv version`, `which python`, `python --version`
- NVM: `nvm current`, `which node`, `node --version`
- Expected: Shims take precedence over system binaries

**Rule 4**: Explicitly confirm testing completion.
- In commit message or task update, state: "Tested: [description]"
- Example: "Tested: Python 3.12.1 via pyenv ✓, Node.js 24.12.0 via NVM ✓"

---

## Repository-Specific Guidelines

### Shell Configuration Changes

- ALWAYS maintain version manager precedence (pyenv, NVM first in PATH)
- NEVER prepend user bins in `.shell_common` (use APPEND on line 48)
- NEVER add oh-my-zsh plugins that conflict with version managers (e.g., `python` plugin)
- Reference: AGENT.md "Shell Configuration Architecture" section

### GNOME Terminal Profile Modifications

- Profiles are binary dconf format (not human-editable)
- Changes require re-extraction on source machine: `01_extract_config.sh`
- Never manually edit `.dconf` files
- UUID regeneration occurs on target during deployment

### Documentation Updates

- If modifying scripts, update line number references in AGENT.md
- If adding new features, update CHANGELOG.md (semantic versioning)
- If changing conventions, update AGENT.md "Development Conventions" section

### Hardcoded Path Changes

- If modifying `.shell_common` aliases, update AGENT.md "Critical File Paths" section
- Update deployment script warning output (deployment/install.sh lines 275-290)

### External Plugin Management

- External plugins (zsh-autosuggestions, zsh-syntax-highlighting) NEVER committed to repo
- Removed during extraction (01_extract_config.sh)
- Re-cloned during installation (deployment/install.sh)
- Ensures target gets latest upstream versions

### Documentation Links

- Reference specific subsections: AGENT.md subsection 1.5 (Shell Configuration Architecture)
- Always link to AGENT.md for architectural questions
- Link to USER_IDENTITY.md for communication style preferences
