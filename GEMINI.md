# Gemini CLI - Agent Context

**MIGRATION NOTICE**: This file has been refactored as part of a centralized agent context architecture (as of 2026-01-14).

**Core Repository Knowledge**: [AGENT.md](AGENT.md)

**User Preferences**: [USER_IDENTITY.md](USER_IDENTITY.md)

**Claude Code Guidelines**: [CLAUDE.md](CLAUDE.md) (for reference)

---

## Quick Repository Summary

### Purpose

This project represents a comprehensive, portable terminal environment configuration for Ubuntu-based systems. It acts as a "Single Source of Truth" for maintaining consistent developer experience across multiple machines.

### Key Components

- **Shell Configs**: `.zshrc`, `.bashrc`, `.shell_common` (SSOT pattern)
- **Oh-My-Zsh Framework**: 143 themes, 354 bundled plugins, external plugins (re-cloned during deployment)
- **Fonts**: JetBrains Mono (34 TTF files, 8.1 MB)
- **GNOME Terminal**: 12 profiles (dconf binary format, UUID-regenerated on deployment)

### Deployment Workflow

**Source Machine** → Extract configs, fonts, profiles → Git → **Target Machine** → Install and validate

**Key Scripts**:
- `bash_scripts_/01_extract_config.sh` - Extract current system state to repo
- `bash_scripts_/02_setup_git_repo.sh` - Initialize Git repository
- `deployment/install.sh` - Deploy on target machine (328 lines)
- `deployment/validate.sh` - Post-deployment verification (450 lines)

### Critical Conventions

1. **Single Source of Truth**: All aliases and PATH logic in `.shell_common` (never duplicate)
2. **Version Manager Precedence**: Pyenv, NVM initialize before oh-my-zsh (PATH order critical)
3. **UUID Regeneration**: GNOME Terminal profiles get new UUIDs on target (prevents collision)
4. **Idempotency**: All scripts safe to re-run (backup-before-overwrite pattern)
5. **External Plugin Freshness**: zsh-autosuggestions and zsh-syntax-highlighting re-cloned on target

### Documentation

For comprehensive architecture and technical details: See [AGENT.md](AGENT.md)

---

## Gemini CLI-Specific Guidelines

### Tool Usage Patterns

**File Operations**:
- Prefer native file reading/editing tools over shell commands
- Read source files before analyzing or suggesting modifications
- Provide context-aware recommendations based on code inspection

**Task Tracking**:
- If Gemini CLI has task management: Use it for multi-step workflows
- Track progress through deployment phases and validation checks

### Interaction Style

**Communication**:
- User demands: Professional, formal, concise, rigorous (see USER_IDENTITY.md)
- Zero fluff, no emojis, no meta-commentary
- Immediate focus on substance and technical accuracy

**Technical Depth**:
- User expects JFM-level rigor (Journal of Fluid Mechanics standard)
- Never hand-wave complex topics
- Provide explicit explanations for architecture decisions

### Repository-Specific Notes

**Shell Configuration Sensitivity**:
- Maintain version manager precedence (see AGENT.md subsection "Version Manager Precedence")
- Never modify PATH order without understanding implications
- Always validate syntax before suggesting deployment

**Documentation Maintenance**:
- Keep AGENT.md updated when architecture changes
- Keep line number references accurate in documentation
- Update CHANGELOG.md for version changes

**Profile and Font Handling**:
- GNOME Terminal profiles are binary dconf format (not human-editable)
- Changes require re-extraction on source machine
- Fonts are binary assets; font management via fontconfig cache rebuild
