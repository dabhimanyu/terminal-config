# Terminal Configuration Project (`terminal-config`)

## Project Overview

This project represents a comprehensive, portable terminal environment configuration designed for Ubuntu-based systems. It acts as a "Single Source of Truth" for maintaining a consistent developer experience across multiple machines.

**Key Features:**
*   **Shell Agnostic Config:** Shared logic resides in `.shell_common`, utilized by both `.zshrc` and `.bashrc`.
*   **Oh-My-Zsh Framework:** Includes a full Oh-My-Zsh setup with themes and plugins (re-cloned during deployment).
*   **Visual Consistency:** Bundles JetBrains Mono fonts (50+ variants) and custom GNOME Terminal profiles (colors, palettes).
*   **Automated Deployment:** Scripts to extract configuration from a source machine and deploy it to a target machine with validation.

## Repository Structure

*   **`shell_configs/`**: Contains the core shell runtime configurations (`.zshrc`, `.bashrc`) and the shared `.shell_common`.
*   **`oh-my-zsh/`**: The Oh-My-Zsh framework directory.
*   **`fonts/`**: A collection of JetBrains Mono `.ttf` files to ensure consistent font rendering.
*   **`dconf/`**: Exported GNOME Terminal profiles in `.dconf` format.
*   **`deployment/`**: Scripts and documentation for installing the configuration on a target machine.
*   **`bash_scripts_/`**: Maintenance scripts for the source machine (extraction, git setup).
*   **`metadata/`**: Inventories of profiles and fonts for validation.

## Deployment Workflow

### 1. On Source Machine (Preparation)
*   **Extraction:** Run `bash_scripts_/01_extract_config.sh` to gather current system configs into the repo structure.
*   **Git Setup:** Run `bash_scripts_/02_setup_git_repo.sh` to initialize/update the git repository.
*   **Add Scripts:** Run `bash_scripts_/03_add_deployment_scripts.sh` to ensure deployment tools are included.

### 2. On Target Machine (Installation)
*   **Clone:** `git clone <repo_url> terminal-config`
*   **Install:** Run `bash deployment/install.sh`. This script:
    *   Backs up existing configs.
    *   Symlinks/copies shell configs.
    *   Installs Oh-My-Zsh and plugins.
    *   Installs fonts.
    *   Imports terminal profiles.
    *   Sets Zsh as the default shell.
*   **Validate:** Run `bash deployment/validate.sh` to ensure all components are correctly installed.

### 3. Post-Deployment Configuration
*   **Path Updates:** Manually edit `~/.shell_common` to update machine-specific paths (e.g., aliases for `obs` or `activate_ai`).
*   **Restart:** Log out and back in to apply the default shell change.

## Key Scripts

### Deployment (`deployment/`)
*   **`install.sh`**: The main entry point for setting up the environment on a new machine. Handles dependency checks, file copying, and system configuration.
*   **`validate.sh`**: A diagnostic tool that checks if the shell, fonts, profiles, and plugins are correctly installed and loaded.
*   **`quick_start.sh`**: An interactive wrapper for the installation process.

### Maintenance (`bash_scripts_/`)
*   **`00_preflight_check.sh`**: Verifies that the source machine has the expected fonts and profiles before extraction.
*   **`01_extract_config.sh`**: Scrapes the current system's configuration to populate the repository folders.
*   **`02_setup_git_repo.sh`**: Automates the git initialization and commit process for the extracted config.

## Development Conventions

*   **Single Source of Truth:** Do not duplicate aliases or path variables between `.zshrc` and `.bashrc`. Put them in `.shell_common`.
*   **Profile Management:** GNOME terminal profiles are binary dconf dumps. Use the extraction scripts to update them; do not edit manually.
*   **Font Management:** Fonts are binary assets stored in `fonts/`. New fonts must be added to the extraction logic if introduced.
*   **Idempotency:** Deployment scripts should be safe to run multiple times without breaking the system (though they may overwrite local changes to config files).
