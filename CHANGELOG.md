# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-01-12

### Added
- Terminal environment extraction pipeline (4-phase): preflight validation, config extraction, Git setup, deployment scaffolding
- Deployment automation: `deployment/install.sh` for target machines, `deployment/validate.sh` for post-deployment verification
- Font management: 34 JetBrains Mono .ttf files with recursive discovery
- GNOME Terminal profile export/import: 12 terminal color profiles (Vs Code Dark+, Catppuccin, Obsidian, etc.)
- Shell configuration: `.zshrc`, `.bashrc`, `.shell_common` with oh-my-zsh framework
- Documentation: `DEPLOY.md` (execution guide), `MASTER_GUIDE.md` (architectural overview)

### Technical Specifications
- Baseline: Ubuntu 20.04.6 LTS, Zsh 5.8, oh-my-zsh framework
- Path dependencies documented (Obsidian vault, AI environment)
- Username-agnostic deployment with UUID regeneration for GNOME profiles
- Recursive font discovery for nested directory structures

### Known Limitations
- Obsidian vault path requires manual adjustment on target machines
- Virtual environment is deployment-specific
- Multi-user scenarios require sed-based username substitution in dconf dump


## [0.2.0-beta] - 2026-01-13

### Fixed
- **CRITICAL:** Removed anti-recursion guard from `.zshrc` that prevented oh-my-zsh from loading after `exec zsh`, breaking custom prompt
- **CRITICAL:** Removed oh-my-zsh `python` plugin that created function wrapper bypassing pyenv shims
- **BUG:** Modified `.shell_common` to APPEND user bins instead of PREPEND, ensuring version managers always take precedence
- **FEATURE:** Added NVM initialization to `.zshrc` for Claude Code and Gemini CLI support

### Known Issues
- Cosmetic duplicate in PATH: `/home/user/.pyenv/plugins/pyenv-virtualenv/shims` appears twice (no functional impact)
- PATH order differs slightly from documentation but is functionally correct

### Testing Status
- Python 3.12.1 via pyenv: ✓ Working
- Node.js 24.12.0 via NVM: ✓ Working
- Custom prompt (green ➜): ✓ Working
- Aliases (obs, activate_ai, ll): ✓ Working

## [0.1.0] - 2026-01-12

### Initial Release (BUGGY - DO NOT USE)
- Anti-recursion guard breaks prompt on reload
- Oh-my-zsh python plugin conflicts with pyenv
- .shell_common PATH order allows future conflicts
