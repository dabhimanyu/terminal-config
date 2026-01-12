# Terminal Configuration for Research Environment

Comprehensive terminal environment configuration for Ubuntu-based systems with Zsh, Oh-My-Zsh, JetBrains Mono fonts, and custom GNOME Terminal profiles.

## Components

- **Shell Configurations** (`.zshrc`, `.bashrc`, `.shell_common`)
  - Single Source of Truth pattern for shared logic
  - Custom aliases and PATH management
  - Virtual environment integration

- **Oh-My-Zsh Framework**
  - Complete framework with themes
  - Plugins (auto-suggestions, syntax highlighting) cloned during deployment

- **JetBrains Mono Fonts**
  - Complete font family included in repository
  - 50+ variants (Regular, Bold, Italic, etc.)

- **GNOME Terminal Profiles**
  - All custom profiles exported
  - Colors, fonts, and palettes preserved
  - UUID-agnostic import on target machine

## Quick Start

### On Source Machine (Already Done)
```bash
# Extract configuration
bash 01_extract_config.sh

# Setup Git repository
bash 02_setup_git_repo.sh
```

### On Target Machine

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/terminal-config.git
cd terminal-config

# Run deployment
bash deployment/install.sh

# Validate installation
bash deployment/validate.sh
```

## Repository Structure

```
terminal-config/
├── README.md                 # This file
├── MANIFEST.md              # Detailed package contents
├── shell_configs/           # Shell RC files
│   ├── .zshrc
│   ├── .bashrc
│   └── .shell_common
├── oh-my-zsh/              # Oh-My-Zsh framework
│   └── .oh-my-zsh/
├── fonts/                   # JetBrains Mono TTF files
│   └── *.ttf
├── dconf/                   # GNOME Terminal profiles
│   └── profile_*.dconf
├── metadata/                # Migration metadata
│   ├── all_profiles.txt
│   ├── default_profile_details.txt
│   └── font_inventory.txt
└── deployment/              # Deployment automation
    ├── install.sh
    ├── validate.sh
    └── DEPLOY.md
```

## Path Dependencies

The following aliases in `.shell_common` contain hardcoded paths that may need updating on the target machine:

- `obs` - Obsidian vault path
- `activate_ai` - Python virtual environment path

Edit `~/.shell_common` after deployment to update these paths.

## Optional: Additional Fonts

To install Fira Code (with ligatures):
```bash
sudo apt install fonts-firacode
fc-cache -f -v
```

## Requirements

- Ubuntu 20.04+ (or compatible Debian-based distribution)
- Zsh 5.8+
- GNOME Terminal 3.36+
- Git 2.25+

## Support

For issues or questions, refer to:
- Deployment documentation: `deployment/DEPLOY.md`
- Validation script: `deployment/validate.sh`
- Migration manifest: `MANIFEST.md`

## License

Personal configuration files. Use and modify as needed.
