# Terminal Configuration Repository - Agent Context

Repository purpose: Portable terminal environment migration system for Ubuntu research environments.

Architecture: Extraction → Git → Deployment pipeline with single-source-of-truth configuration pattern.

Version: 1.0.0

## Quick Reference
- **User Preferences**: [USER_IDENTITY.md](USER_IDENTITY.md)
- **Claude Code Guidelines**: [CLAUDE.md](CLAUDE.md)
- **Gemini CLI Guidelines**: [GEMINI.md](GEMINI.md)
- **New Agent Onboarding**: [TEMPLATE.md](TEMPLATE.md)

## Agent Progress Communication (Strict)

**Rule**: All agents MUST share real-time progress updates with user.
- **Frequency**: After each significant task completion (file created, merge complete, validation passed)
- **Tone**: Low verbosity, dense, brief status lines (no fluff)
- **Format**: Bullet list with checkmarks, line counts, completion percentage
- **Example**: ✅ AGENT.md (511 lines) ✅ CLAUDE.md (204 lines) ⏳ Verification (1/3 checks)
- **Rationale**: User demands visibility into work in progress; prevents token burn while keeping user informed

---

## Repository Philosophy

### Single Source of Truth (SSOT)

Core principle: One authoritative location for each piece of logic. All shell aliases and PATH management reside exclusively in `.shell_common`, sourced by both `.zshrc` (Zsh) and `.bashrc` (Bash). Duplication is forbidden; maintenance drift and divergence risk increase with every duplicate.

### Idempotency by Design

All deployment scripts are safe to re-run. No destructive operations without backup-before-overwrite. Timestamped backups (e.g., `.zshrc.pre-migration-20260112_221948`) enable safe rollback if needed.

### UUID-Agnostic GNOME Terminal Deployment

GNOME Terminal profiles use UUID-based keys in dconf. On target machines, profiles are regenerated with new UUIDs via `uuidgen` to prevent collision with existing profiles. This enables reliable multi-machine deployment without namespace conflicts.

### Version Manager Precedence (Critical)

PATH order: `pyenv shims → NVM bins → user bins → system binaries`

Pyenv and NVM initialize BEFORE oh-my-zsh loads in `.zshrc` (lines 5-30). User bins are APPENDED (not prepended) to PATH via `.shell_common` (line 48). This preserves version manager precedence; if user bins prepend, they override version manager shims, causing Python/Node.js resolution to fail.

**Bug History**: v0.1.0 had PATH order reversed (user bins first), breaking pyenv resolution. v0.2.0-beta corrected this.

---

## Architecture Overview

### Three-Phase Lifecycle

**Source Machine (Preparation)**:
1. `00_preflight_check.sh` - Validate current system state
2. `01_extract_config.sh` - Extract configs, fonts, profiles to repo
3. `02_setup_git_repo.sh` - Initialize Git repository
4. `03_add_deployment_scripts.sh` - Add deployment tools to repo

**Git Transport**: Push to GitHub/GitLab, version control for distribution

**Target Machine (Installation)**:
1. `git clone <repo_url> terminal-config`
2. `bash deployment/install.sh` - Deploy all components
3. `bash deployment/validate.sh` - Verify installation

### Component Inventory

| Component | Count | Location | Deployment |
|-----------|-------|----------|------------|
| Shell configs | 3 files | `shell_configs/` | Copy to `~/` |
| Oh-My-Zsh framework | 1 directory | `oh-my-zsh/.oh-my-zsh/` | Copy to `~/.oh-my-zsh/` |
| Themes | 143 files | `.oh-my-zsh/themes/` | Included in framework |
| Bundled plugins | 354 directories | `.oh-my-zsh/plugins/` | Included in framework |
| External plugins | 2 repos | N/A | Re-cloned on target |
| Fonts (JetBrains Mono) | 34 TTF files | `fonts/` | Copy to `~/.local/share/fonts/` |
| Terminal profiles | 12 dconf exports | `dconf/` | Import via `dconf load` |

---

## Directory Structure

```
terminal-config/
├── shell_configs/                     # Shell runtime configurations
│   ├── .zshrc                         # Zsh: pyenv, NVM, oh-my-zsh init, custom prompt
│   ├── .bashrc                        # Bash: fallback compatibility, sources .shell_common
│   └── .shell_common                  # SSOT: aliases, PATH mgmt, virtualenv settings
│
├── oh-my-zsh/
│   └── .oh-my-zsh/                    # Framework: 143 themes, 354 plugins, core lib
│       ├── custom/                    # User customizations (external plugins excluded)
│       ├── themes/                    # Bundled themes (agnoster, robbyrussell, etc.)
│       └── plugins/                   # Bundled plugins (git, pip, virtualenv, etc.)
│
├── fonts/                             # JetBrains Mono: 34 TTF files (8.1 MB)
│   └── JetBrainsMono*.ttf            # Regular, Bold, Italic, Light, ExtraBold variants
│
├── dconf/                             # GNOME Terminal: 12 profile exports
│   └── profile_<UUID>.dconf          # Binary dconf format (colors, fonts, palettes)
│
├── metadata/                          # Validation manifests
│   ├── all_profiles.txt              # Profile inventory
│   ├── default_profile_details.txt   # Default: "Vs Code Dark+", JetBrains Mono 12
│   └── font_inventory.txt            # Font files with sizes
│
├── bash_scripts_/                     # Source machine: extraction phase
│   ├── 00_preflight_check.sh         # Pre-extraction validation
│   ├── 01_extract_config.sh          # Extract configs to repo
│   ├── 02_setup_git_repo.sh          # Git init and commit
│   ├── 03_add_deployment_scripts.sh  # Copy deployment tools
│   ├── DEPLOY.md                     # Deployment execution guide (551 lines)
│   └── MASTER_GUIDE.md               # Architectural overview (658 lines)
│
├── deployment/                        # Target machine: installation phase
│   ├── install.sh                    # Main deployment script (328 lines)
│   ├── validate.sh                   # Post-deployment validation (450 lines)
│   └── DEPLOY.md                     # Detailed deployment instructions
│
├── AGENT.md                           # Repository encyclopedia (this file)
├── CLAUDE.md                          # Claude Code CLI guidelines
├── GEMINI.md                          # Gemini CLI guidelines
├── TEMPLATE.md                        # New agent onboarding template
├── USER_IDENTITY.md                   # User preferences and cognitive style
├── README.md                          # GitHub landing page
├── MANIFEST.md                        # Package contents inventory
├── CHANGELOG.md                       # Version history
└── VERSION                            # Semantic version (1.0.0)
```

---

## Shell Configuration Architecture

### Initialization Order (Critical)

`.zshrc` execution sequence:

1. **Export PYENV_ROOT** (lines 14-19): Set directory and check for duplicates in PATH
2. **Initialize pyenv** (lines 21-22): Load shims and virtualenv support
3. **Initialize NVM** (lines 28-30): Node version manager initialization
4. **Load oh-my-zsh** (line 54): Framework loader with plugins
5. **Define custom prompt** (line 64): Exit code indicator + virtualenv prefix + current directory
6. **Configure history** (lines 69-72): HISTSIZE, SAVEHIST, history options
7. **Source .shell_common** (line 79): Aliases, PATH additions, virtualenv settings (LAST)

**Why last?** Version managers must initialize and set up their PATH entries BEFORE .shell_common appends user bins. This preserves precedence.

### Version Manager Precedence

**Problem**: If user bins prepend PATH, they override version manager shims.

**Example conflict** (if .shell_common prepended):
```
User runs: pip install --user some-package
→ Installs to ~/.local/bin/
→ If ~/.local/bin is FIRST in PATH, it overrides pyenv shims
→ which python → ~/.local/bin/python (WRONG, bypasses pyenv)
```

**Solution**: `.shell_common` line 48 appends user bins to PATH end.

**Result**: PATH order = `pyenv shims:NVM bins:user bins:system bins`

### .shell_common Pattern

**Purpose**: Single source of truth for bash/zsh shared logic.

**Contents**:
- Aliases: `activate_ai`, `obs`, `ll`, `la`, `l`
- Virtualenv setting: `VIRTUAL_ENV_DISABLE_PROMPT=1` (suppress double prompt)
- PATH additions: `~/bin`, `~/.local/bin` (with deduplication)

**Why not duplicate?** Maintenance: change once, applies to both shells. Consistency: both shells behave identically. Debugging: one file to inspect.

### Oh-My-Zsh Python Plugin Removal

**Bug (v0.1.0)**: `python` plugin created function wrapper calling `pyenv exec python`.

**Problem**: Wrapper bypassed PATH resolution, used `.python-version` files instead. `which python` returned function name, not shim path.

**Fix (v0.2.0-beta)**: Removed `python` from plugins list (line 44).

**Result**: `which python` correctly returns pyenv shim path.

### Anti-Recursion Guard Removal

**Bug (v0.1.0)**: Guard prevented oh-my-zsh from loading after `exec zsh`.

**Symptom**: Custom prompt disappeared after shell reload.

**Fix (v0.2.0-beta)**: Removed guard entirely. Oh-my-zsh has internal recursion protection.

---

## Oh-My-Zsh Integration

### Framework Composition

- **Core**: `oh-my-zsh.sh` (framework loader)
- **Themes**: 143 bundled themes in `themes/`
- **Bundled Plugins**: 354 directories in `plugins/` (git, pip, docker, kubectl, etc.)
- **External Plugins** (re-cloned during deployment):
  - `zsh-autosuggestions` - Fish-like autosuggestions
  - `zsh-syntax-highlighting` - Command syntax highlighting

### Deployment Strategy

**Extraction Phase** (`01_extract_config.sh`):

```bash
cp -r ~/.oh-my-zsh "$MIGRATION_DIR/oh_my_zsh/"
# Remove external plugins (ensure target gets latest versions)
rm -rf custom/plugins/zsh-autosuggestions
rm -rf custom/plugins/zsh-syntax-highlighting
```

**Installation Phase** (`deployment/install.sh`):

```bash
cp -r "$REPO_ROOT/oh-my-zsh/.oh-my-zsh" ~/
# Re-clone external plugins from upstream
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

Why remove/re-clone? Ensures target gets latest plugin versions with security patches.

### Custom Prompt Design

**Format**: `[exit_code_indicator] [venv_if_active] current_dir`

**Implementation** (`.zshrc` line 64):
```bash
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg_bold[blue]%}\$(virtualenv_prompt_info)%{$fg[cyan]%}%c%{$reset_color%} "
```

**Behavior**:
- Green `➜` on success (exit code 0)
- Red `➜` on failure (non-zero)
- Blue `(venv_name)` prefix when virtualenv active
- Cyan current directory name

---

## Font Management

### Font Inventory

- **Family**: JetBrains Mono
- **Count**: 34 TTF files
- **Total Size**: 8.1 MB
- **Variants**: Regular, Bold, Italic, Light, Thin, ExtraBold, ExtraLight
- **Variable Fonts**: `JetBrainsMono[wght].ttf`, `JetBrainsMono-Italic[wght].ttf`

### Extraction Process

**Script**: `01_extract_config.sh` (recursive search for nested directories)

```bash
find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -type f -exec cp {} "$MIGRATION_DIR/fonts/" \;
ls -lh "$MIGRATION_DIR/fonts"/*.ttf > "$MIGRATION_DIR/metadata/font_inventory.txt"
```

### Installation Process

**Script**: `deployment/install.sh`

```bash
mkdir -p ~/.local/share/fonts/
cp "$REPO_ROOT"/fonts/*.ttf ~/.local/share/fonts/
fc-cache -f -v  # Rebuild font cache (CRITICAL STEP)
```

### Validation

```bash
fc-list | grep -i "JetBrains Mono" | wc -l
# Expected: 34+ entries (includes variants)
```

---

## GNOME Terminal Profile System

### Profile Architecture

**Technology**: dconf (binary configuration format for GNOME)
**Storage**: `/org/gnome/terminal/legacy/profiles:/`
**Profile Count**: 12
**Default Profile**: "Vs Code Dark+" (UUID: `934a1a08-5d50-4a6e-aa06-f68537fb48d9`)

**Profile List**:
1. Vs Code Dark+ (DEFAULT)
2. Elic
3. Catppuccin Frappé
4. Cobalt Neon
5. Chalk
6. Base4Tone Classic I
7. Everblush
8. Abhi_Ubunto_Profile_
9. Dehydration
10. Spacedust
11. Atelier Sulphurpool
12. Obsidian

### Export Process

**Script**: `01_extract_config.sh`

```bash
DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default | tr -d "'")
PROFILE_LIST=$(dconf read /org/gnome/terminal/legacy/profiles:/list | tr -d "[]'," | tr ' ' '\n')

for UUID in $PROFILE_LIST; do
    dconf dump "/org/gnome/terminal/legacy/profiles:/:$UUID/" > "$MIGRATION_DIR/dconf/profile_${UUID}.dconf"
done
```

**Output**: 12 `.dconf` files with original UUIDs.

### Import Process (UUID Regeneration)

**Script**: `deployment/install.sh`

**Problem**: Source UUIDs may conflict with target machine's existing profiles.

**Solution**: Generate new UUIDs for each profile.

```bash
NEW_UUIDS=()
for i in {1..12}; do
    NEW_UUIDS+=("$(uuidgen)")
done

for i in "${!DCONF_FILES[@]}"; do
    NEW_UUID="${NEW_UUIDS[$i]}"
    dconf load "/org/gnome/terminal/legacy/profiles:/:$NEW_UUID/" < "$DCONF_FILE"
done

PROFILE_LIST=$(printf ",'%s'" "${NEW_UUIDS[@]}")
PROFILE_LIST="[${PROFILE_LIST:1}]"
dconf write /org/gnome/terminal/legacy/profiles:/list "$PROFILE_LIST"
dconf write /org/gnome/terminal/legacy/profiles:/default "'${NEW_UUIDS[0]}'"
```

### Profile Configuration

**Typical Profile Contents**:
```
visible-name='Vs Code Dark+'
font='JetBrains Mono 12'
use-system-font=false
background-color='rgb(30,30,30)'
foreground-color='rgb(204,204,204)'
palette=['rgb(0,0,0)', 'rgb(205,49,49)', ...]
```

### Validation

```bash
# Check profile count
dconf read /org/gnome/terminal/legacy/profiles:/list | grep -o "'" | wc -l
# Expected: 24 (12 profiles × 2 quotes per UUID)

# Check default profile set
dconf read /org/gnome/terminal/legacy/profiles:/default
# Expected: Non-empty UUID string

# Check default profile name
DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default | tr -d "'")
dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/visible-name"
# Expected: 'Vs Code Dark+'
```

---

## Deployment Workflow

### Phase 1: Source Machine Extraction

**Scripts** (in order):
1. `00_preflight_check.sh` - Validates fonts, profiles exist
2. `01_extract_config.sh` - Copies configs, fonts, profiles to workspace
3. `02_setup_git_repo.sh` - Initializes Git repository
4. `03_add_deployment_scripts.sh` - Adds deployment tools to repo

**Output**: `~/terminal_migration_<timestamp>/` directory with all components ready for Git.

### Phase 2: Git Setup

**Script**: `02_setup_git_repo.sh`

**Actions**:
1. `git init` in migration directory
2. `git add .` (all extracted files)
3. `git commit -m "feat: Initialize terminal migration infrastructure"`
4. Create `.gitignore` (excludes: `*.tar.gz`, `*.zip`, `__pycache__/`, `.DS_Store`)
5. Prompt user to create remote and push

### Phase 3: Target Machine Deployment

**Script**: `deployment/install.sh` (328 lines)

**Phase 3a: Prerequisites** (lines 34-54)
- Install packages: `zsh`, `git`, `curl`, `wget`, `unzip`, `dconf-cli`, `fontconfig`
- Update package cache: `sudo apt update`

**Phase 3b: Shell configs** (lines 59-76)
- Backup existing: `.zshrc.pre-migration-<timestamp>`
- Copy files: `.zshrc`, `.bashrc`, `.shell_common` to `~/`

**Phase 3c: Oh-My-Zsh framework** (lines 81-97)
- Backup existing: `.oh-my-zsh.pre-migration-<timestamp>`
- Copy framework: `cp -r $REPO_ROOT/oh-my-zsh/.oh-my-zsh ~/`

**Phase 3d: External plugins** (lines 100-125)
- Clone from upstream (gets latest versions)

**Phase 3e: Fonts** (lines 170-185)
- Copy to `~/.local/share/fonts/`
- Rebuild cache: `fc-cache -f -v`

**Phase 3f: Terminal profiles** (lines 190-250)
- Import with UUID regeneration

**Phase 3g: Default shell** (lines 255-270)
- Set Zsh: `chsh -s $(which zsh)`
- Warn user to log out/in

**Phase 3h: Path validation** (lines 275-290)
- Warn about hardcoded paths in `.shell_common` requiring manual updates

### Phase 4: Validation

**Script**: `deployment/validate.sh` (450 lines)

**Checks**:
1. Default shell is Zsh
2. Config files exist: `.zshrc`, `.bashrc`, `.shell_common`
3. Oh-My-Zsh framework present: `~/.oh-my-zsh/`
4. External plugins cloned
5. Fonts installed: `fc-list | grep "JetBrains Mono"`
6. Terminal profiles imported: count = 12
7. Default profile set
8. Version managers working (if installed): pyenv, NVM

**Pass Criteria**: All checks return `✓`. Fail count = 0.

---

## Development Conventions

**Convention 1: Single Source of Truth**
- Rule: Never duplicate logic between `.zshrc` and `.bashrc`
- Enforcement: Shared logic goes in `.shell_common`

**Convention 2: Idempotency**
- Rule: All scripts safe to re-run
- Implementation: Check existence before mutation
- Example: Backup with timestamp before overwrite

**Convention 3: Backup-Before-Overwrite**
- Rule: Never destructively overwrite without backup
- Pattern: `<filename>.pre-migration-<timestamp>`

**Convention 4: Version Manager Precedence**
- Rule: Version managers always take PATH priority
- Implementation: APPEND user bins (line 48 of `.shell_common`)

**Convention 5: Oh-My-Zsh Plugin Compatibility**
- Rule: Remove plugins that conflict with version managers
- Current Exclusion: `python` plugin (conflicts with pyenv)

**Convention 6: UUID Regeneration**
- Rule: GNOME Terminal profiles get new UUIDs on target
- Rationale: Prevents collision with existing profiles

**Convention 7: External Plugin Freshness**
- Rule: External plugins cloned from upstream, not committed to repo
- Enforcement: Removed during extraction, re-cloned during installation

---

## Version History

### v1.0.0 (2026-01-12) - Initial Release
- Extraction pipeline: 4-phase (preflight, extract, git, deployment)
- Components: Shell configs, Oh-My-Zsh, 34 fonts, 12 profiles
- Documentation: DEPLOY.md (551 lines), MASTER_GUIDE.md (658 lines)
- Baseline: Ubuntu 20.04.6 LTS, Zsh 5.8

### v0.2.0-beta (2026-01-13) - Critical Bugfixes
- **CRITICAL FIX**: Removed anti-recursion guard from `.zshrc` (broke custom prompt after `exec zsh`)
- **CRITICAL FIX**: Removed oh-my-zsh `python` plugin (function wrapper bypassed pyenv shims)
- **BUG FIX**: Modified `.shell_common` to APPEND user bins (preserves version manager precedence)
- **FEATURE**: Added NVM initialization to `.zshrc`

### v0.1.0 (2026-01-12) - DEPRECATED (DO NOT USE)
- Anti-recursion guard breaks prompt on reload
- Python plugin conflicts with pyenv
- PATH order bug (user bins override version managers)

---

## Critical File Paths (Requiring Manual Update)

### File: `shell_configs/.shell_common`

**Line 9**: Obsidian vault alias
```bash
alias obs='obsidian vault open "/media/user/New Volume/Downloads/##_MarkDown_Files_"'
```
**Update Required**: Change path to match target machine's Obsidian vault location.

**Line 10**: Python virtual environment alias
```bash
alias activate_ai='source ~/neural_computing/ai_env/bin/activate'
```
**Update Required**: Change `~/neural_computing/ai_env/` to target machine's venv path.

### Path Dependencies

- `/media/user/New Volume/` assumes external drive mounted at this path
- `~/neural_computing/ai_env/` assumes venv exists at this location
- `.shell_common` sources assume username = `user`

### Deployment Script Warnings

**Script**: `deployment/install.sh` (lines 275-290)

**Warning Output**:
```
▶ Phase 8: Checking path-dependent aliases
⚠ The following aliases contain hardcoded paths that may need updating:
- Line 9: alias obs='obsidian vault open "/media/user/New Volume/Downloads/##_MarkDown_Files_"'
- Line 10: alias activate_ai='source ~/neural_computing/ai_env/bin/activate'

ACTION REQUIRED: Edit ~/.shell_common and update paths to match your system.
```

---

## Technical Specifications

### Software Requirements

**Operating System**: Ubuntu 20.04+ (or compatible Debian-based distribution)
**Kernel**: 5.15.0+
**Desktop Environment**: GNOME 3.36+

**Shell Requirements**:
- Zsh: 5.8+
- Bash: 5.0+ (fallback compatibility)
- GNOME Terminal: 3.36+

**Version Managers** (optional but recommended):
- Pyenv: 2.0+ (Python version management)
- Pyenv-virtualenv: 1.1+ (Python virtual environments)
- NVM: 0.39+ (Node.js version management)

**System Tools**:
- Git: 2.25+
- dconf: 0.36+ (GNOME configuration)
- fontconfig: 2.13+ (font management)
- curl/wget: Any version

### File Formats

**Shell Configs**: Plain text, UTF-8, no shebang (sourced, not executed)

**dconf Profiles**: Binary dconf dump, UTF-8 text representation, GVariant format

**Fonts**: TrueType Font (TTF), OpenType 1.8, SIL Open Font License 1.1

### Data Integrity

**Checksums**: MD5 (documented in MANIFEST.md)

**Validation**: Run `md5sum -c <checksums_file>` to verify file integrity.

---

## Terminology

**Single Source of Truth (SSOT)**: One authoritative location for each piece of logic. Example: `.shell_common` is SSOT for aliases shared between bash/zsh.

**Idempotency**: Operation produces same result regardless of how many times executed. Example: `install.sh` can be re-run without breaking system.

**Version Manager**: Tool for managing multiple versions of programming languages. Examples: pyenv (Python), NVM (Node.js).

**Shim**: Lightweight wrapper script that delegates to version manager. Location: `~/.pyenv/shims/`, `~/.nvm/versions/node/*/bin/`.

**dconf**: Binary configuration database for GNOME applications. Storage: `/org/gnome/...` hierarchical key paths.

**UUID**: 128-bit identifier (RFC 4122). Format: `934a1a08-5d50-4a6e-aa06-f68537fb48d9`. Purpose: Unique keys for GNOME Terminal profiles.

**PATH Precedence**: Order in which directories are searched for executables. Rule: First match wins (leftmost directory takes priority).
