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
