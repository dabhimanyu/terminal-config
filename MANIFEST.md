# Terminal Environment Migration Package

**Package ID:** terminal_migration_20260112_221948  
**Generated:** Monday 12 January 2026 10:19:48 PM IST  
**Source Hostname:** user-HP-Z400-Workstation  
**Source User:** user  
**Source OS:** Ubuntu 20.04.6 LTS  
**Source Kernel:** 5.15.0-139-generic

---

## Package Contents

### 1. Shell Configuration Files (`shell_configs/`)
- `.zshrc` - Zsh runtime configuration
- `.bashrc` - Bash runtime configuration (fallback/compatibility)
- `.shell_common` - Shared aliases and PATH logic (Single Source of Truth)

### 2. Oh-My-Zsh Framework (`oh_my_zsh/`)
- Complete framework directory
- Themes preserved
- Plugins EXCLUDED (will be re-cloned from upstream during deployment)

### 3. Font Assets (`fonts/`)
- JetBrains Mono font family: 34 .ttf files
- See `metadata/font_inventory.txt` for complete list

### 4. GNOME Terminal Profiles (`dconf/`)
- Total profiles: 12
- Default profile UUID: 934a1a08-5d50-4a6e-aa06-f68537fb48d9
- Default profile name: \"Vs Code Dark+\"
- See `metadata/all_profiles.txt` for complete inventory

### 5. Metadata (`metadata/`)
- `all_profiles.txt` - Complete profile inventory with UUIDs
- `default_profile_details.txt` - Default profile configuration
- `font_inventory.txt` - Font file listing

---

## Critical Path Dependencies

The following aliases in `.shell_common` contain hardcoded paths:

```bash
alias activate_ai='source ~/neural_computing/ai_env/bin/activate'
alias obs='obsidian vault open "/media/user/New Volume/Downloads/##_MarkDown_Files_"'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
```

**⚠ ACTION REQUIRED:** Update these paths on the target machine if:
- Username differs
- Mount points differ
- Virtual environment paths differ

---

## Virtual Environment Dependencies

The following virtual environments are referenced but NOT included:

```
source ~/neural_computing/ai_env/bin/activate
```

These must be recreated on the target machine.

---

## Deployment Instructions

1. Transfer this migration package to the target machine
2. Extract: `tar -xzf terminal_backup_20260112_221948.tar.gz`
3. Navigate to repository: `cd terminal-config/`
4. Run deployment script: `bash deployment/install.sh`
5. Log out and log back in
6. Run validation: `bash deployment/validate.sh`

Detailed instructions: See `deployment/DEPLOY.md`

---

## Verification Checksums

```
6b35682bf2b51d7f9a5f1795375caae8  /home/user/terminal_migration_20260112_221948/shell_configs/.zshrc
5abd3cf0c527728f57593b2966cc0c5b  /home/user/terminal_migration_20260112_221948/shell_configs/.bashrc
6916a36fb69ebf8b0ea83313fc99a036  /home/user/terminal_migration_20260112_221948/fonts/JetBrainsMonoNL-Light.ttf
d09f65145228b709a10fa0a06d522d89  /home/user/terminal_migration_20260112_221948/fonts/JetBrainsMono-Regular.ttf
b4de3b330494410118d5db620c179765  /home/user/terminal_migration_20260112_221948/fonts/JetBrainsMono-ExtraBoldItalic.ttf
4bd4e9f58ecb11162e28892808b30461  /home/user/terminal_migration_20260112_221948/fonts/JetBrainsMonoNL-ExtraLightItalic.ttf
2fc48b74e455336b33a334cb95dd07b9  /home/user/terminal_migration_20260112_221948/fonts/JetBrainsMonoNL-BoldItalic.ttf
4e546cf31f9ad0c6c43a0c9abbc9f9d4  /home/user/terminal_migration_20260112_221948/fonts/JetBrainsMono[wght].ttf
a6d89cbaeda9ce8e23109383e0722f76  /home/user/terminal_migration_20260112_221948/fonts/JetBrainsMono-BoldItalic.ttf
54849b7b14a6f0cbc2cd3aabc4edf38b  /home/user/terminal_migration_20260112_221948/fonts/JetBrainsMono-ThinItalic.ttf
```

---

**Migration Package Ready for Transport**
