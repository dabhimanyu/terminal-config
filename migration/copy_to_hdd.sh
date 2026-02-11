#!/usr/bin/env bash
#
# copy_to_hdd.sh - Copy migration package to external HDD
#
# This script copies the migration package and related files to an external HDD
# for backup before workstation migration.
#
# Usage:
#   ./copy_to_hdd.sh [--dry-run]
#
# Options:
#   --dry-run    Show what would be copied without actually copying
#

set -euo pipefail

# Configuration
HDD_BASE_DIR="/media/user/Abhi_HDD-3/IISc_PC_BackUp_/Old_Workstation_Backup_of_Home_Directory_NO_Sym_Links_"
HOME_DIR="${HOME}"
MIGRATION_DIR="${HOME_DIR}/migration_package"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Parse command line arguments
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    print_header "DRY RUN MODE - No files will be copied"
fi

# Main execution
main() {
    print_header "Migration Package HDD Backup"

    # Step 1: Check if HDD directory exists
    print_info "Checking if HDD directory exists..."
    if [[ ! -d "${HDD_BASE_DIR}" ]]; then
        print_error "HDD directory not found: ${HDD_BASE_DIR}"
        print_error "Please ensure the external HDD is mounted and the path is correct."
        exit 1
    fi
    print_success "HDD directory found: ${HDD_BASE_DIR}"

    # Step 2: Create timestamped subdirectory
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="${HDD_BASE_DIR}/migration_backup_${TIMESTAMP}"

    if [[ "${DRY_RUN}" == false ]]; then
        mkdir -p "${BACKUP_DIR}"
        print_success "Created backup directory: ${BACKUP_DIR}"
    else
        print_info "[DRY-RUN] Would create directory: ${BACKUP_DIR}"
    fi

    # Initialize summary variables
    declare -a COPIED_FILES
    declare -a FAILED_FILES
    TOTAL_SIZE=0

    # Step 3: Copy files
    print_header "Copying Migration Files"

    # 3a: Copy unencrypted archive
    print_info "Looking for unencrypted migration package..."
    UNENCRYPTED_ARCHIVE=$(find "${HOME_DIR}" -maxdepth 1 -name "migration_package_UNENCRYPTED_*.tar.gz" -type f | head -n 1)
    if [[ -n "${UNENCRYPTED_ARCHIVE}" ]]; then
        FILE_SIZE=$(stat -f%z "${UNENCRYPTED_ARCHIVE}" 2>/dev/null || stat -c%s "${UNENCRYPTED_ARCHIVE}" 2>/dev/null || echo "0")
        if [[ "${DRY_RUN}" == true ]]; then
            print_info "[DRY-RUN] Would copy: ${UNENCRYPTED_ARCHIVE}"
            COPIED_FILES+=("${UNENCRYPTED_ARCHIVE} -> ${BACKUP_DIR}/")
            TOTAL_SIZE=$((TOTAL_SIZE + FILE_SIZE))
        else
            if cp "${UNENCRYPTED_ARCHIVE}" "${BACKUP_DIR}/"; then
                if [[ -f "${BACKUP_DIR}/$(basename "${UNENCRYPTED_ARCHIVE}")" ]]; then
                    print_success "Copied: $(basename "${UNENCRYPTED_ARCHIVE}")"
                    COPIED_FILES+=("${UNENCRYPTED_ARCHIVE}")
                    TOTAL_SIZE=$((TOTAL_SIZE + FILE_SIZE))
                else
                    print_error "Verification failed for: $(basename "${UNENCRYPTED_ARCHIVE}")"
                    FAILED_FILES+=("${UNENCRYPTED_ARCHIVE}")
                fi
            else
                print_error "Failed to copy: $(basename "${UNENCRYPTED_ARCHIVE}")"
                FAILED_FILES+=("${UNENCRYPTED_ARCHIVE}")
            fi
        fi
    else
        print_warning "No unencrypted archive found (migration_package_UNENCRYPTED_*.tar.gz)"
    fi

    # 3b: Copy encrypted archive
    print_info "Looking for encrypted migration package..."
    ENCRYPTED_ARCHIVE=$(find "${HOME_DIR}" -maxdepth 1 -name "migration_package_*.tar.gz.gpg" -type f | head -n 1)
    if [[ -n "${ENCRYPTED_ARCHIVE}" ]]; then
        FILE_SIZE=$(stat -f%z "${ENCRYPTED_ARCHIVE}" 2>/dev/null || stat -c%s "${ENCRYPTED_ARCHIVE}" 2>/dev/null || echo "0")
        if [[ "${DRY_RUN}" == true ]]; then
            print_info "[DRY-RUN] Would copy: ${ENCRYPTED_ARCHIVE}"
            COPIED_FILES+=("${ENCRYPTED_ARCHIVE} -> ${BACKUP_DIR}/")
            TOTAL_SIZE=$((TOTAL_SIZE + FILE_SIZE))
        else
            if cp "${ENCRYPTED_ARCHIVE}" "${BACKUP_DIR}/"; then
                if [[ -f "${BACKUP_DIR}/$(basename "${ENCRYPTED_ARCHIVE}")" ]]; then
                    print_success "Copied: $(basename "${ENCRYPTED_ARCHIVE}")"
                    COPIED_FILES+=("${ENCRYPTED_ARCHIVE}")
                    TOTAL_SIZE=$((TOTAL_SIZE + FILE_SIZE))
                else
                    print_error "Verification failed for: $(basename "${ENCRYPTED_ARCHIVE}")"
                    FAILED_FILES+=("${ENCRYPTED_ARCHIVE}")
                fi
            else
                print_error "Failed to copy: $(basename "${ENCRYPTED_ARCHIVE}")"
                FAILED_FILES+=("${ENCRYPTED_ARCHIVE}")
            fi
        fi
    else
        print_warning "No encrypted archive found (migration_package_*.tar.gz.gpg)"
    fi

    # 3c: Copy migration_package directory
    print_info "Looking for migration_package directory..."
    if [[ -d "${MIGRATION_DIR}" ]]; then
        if [[ "${DRY_RUN}" == true ]]; then
            print_info "[DRY-RUN] Would copy directory: ${MIGRATION_DIR}"
            COPIED_FILES+=("${MIGRATION_DIR}/ -> ${BACKUP_DIR}/migration_package/")
        else
            if rsync -av "${MIGRATION_DIR}/" "${BACKUP_DIR}/migration_package/"; then
                if [[ -d "${BACKUP_DIR}/migration_package" ]]; then
                    DIR_SIZE=$(du -sb "${MIGRATION_DIR}" | cut -f1)
                    print_success "Copied directory: migration_package/"
                    COPIED_FILES+=("${MIGRATION_DIR}")
                    TOTAL_SIZE=$((TOTAL_SIZE + DIR_SIZE))
                else
                    print_error "Verification failed for: migration_package/"
                    FAILED_FILES+=("${MIGRATION_DIR}")
                fi
            else
                print_error "Failed to copy: migration_package/"
                FAILED_FILES+=("${MIGRATION_DIR}")
            fi
        fi
    else
        print_warning "Migration package directory not found: ${MIGRATION_DIR}"
    fi

    # 3d: Copy .ssh directory
    print_header "Copying SSH Configuration"
    if [[ -d "${HOME_DIR}/.ssh" ]]; then
        if [[ "${DRY_RUN}" == true ]]; then
            print_info "[DRY-RUN] Would copy directory: ${HOME_DIR}/.ssh"
            COPIED_FILES+=("${HOME_DIR}/.ssh/ -> ${BACKUP_DIR}/.ssh/")
        else
            if rsync -av "${HOME_DIR}/.ssh/" "${BACKUP_DIR}/.ssh/"; then
                if [[ -d "${BACKUP_DIR}/.ssh" ]]; then
                    DIR_SIZE=$(du -sb "${HOME_DIR}/.ssh" | cut -f1)
                    print_success "Copied directory: .ssh/"
                    COPIED_FILES+=("${HOME_DIR}/.ssh")
                    TOTAL_SIZE=$((TOTAL_SIZE + DIR_SIZE))
                    print_warning "NOTE: Private keys may have restricted permissions. Verify on HDD."
                else
                    print_error "Verification failed for: .ssh/"
                    FAILED_FILES+=("${HOME_DIR}/.ssh")
                fi
            else
                print_error "Failed to copy: .ssh/"
                FAILED_FILES+=("${HOME_DIR}/.ssh")
            fi
        fi
    else
        print_warning ".ssh directory not found"
    fi

    # 3e: Copy .gnupg directory
    print_header "Copying GPG Configuration"
    if [[ -d "${HOME_DIR}/.gnupg" ]]; then
        if [[ "${DRY_RUN}" == true ]]; then
            print_info "[DRY-RUN] Would copy directory: ${HOME_DIR}/.gnupg"
            COPIED_FILES+=("${HOME_DIR}/.gnupg/ -> ${BACKUP_DIR}/.gnupg/")
        else
            if rsync -av "${HOME_DIR}/.gnupg/" "${BACKUP_DIR}/.gnupg/"; then
                if [[ -d "${BACKUP_DIR}/.gnupg" ]]; then
                    DIR_SIZE=$(du -sb "${HOME_DIR}/.gnupg" | cut -f1)
                    print_success "Copied directory: .gnupg/"
                    COPIED_FILES+=("${HOME_DIR}/.gnupg")
                    TOTAL_SIZE=$((TOTAL_SIZE + DIR_SIZE))
                    print_warning "NOTE: GPG private keys require special handling. Verify on HDD."
                else
                    print_error "Verification failed for: .gnupg/"
                    FAILED_FILES+=("${HOME_DIR}/.gnupg")
                fi
            else
                print_error "Failed to copy: .gnupg/"
                FAILED_FILES+=("${HOME_DIR}/.gnupg")
            fi
        fi
    else
        print_warning ".gnupg directory not found"
    fi

    # Step 4: Print summary
    print_header "Backup Summary"

    # Format total size
    if [[ ${TOTAL_SIZE} -gt 1073741824 ]]; then
        SIZE_HR="$(awk "BEGIN {printf \"%.2f\", ${TOTAL_SIZE}/1073741824}") GB"
    elif [[ ${TOTAL_SIZE} -gt 1048576 ]]; then
        SIZE_HR="$(awk "BEGIN {printf \"%.2f\", ${TOTAL_SIZE}/1048576}") MB"
    elif [[ ${TOTAL_SIZE} -gt 1024 ]]; then
        SIZE_HR="$(awk "BEGIN {printf \"%.2f\", ${TOTAL_SIZE}/1024}") KB"
    else
        SIZE_HR="${TOTAL_SIZE} bytes"
    fi

    echo -e "${BLUE}Backup Location:${NC} ${BACKUP_DIR}"
    echo -e "${BLUE}Total Size:${NC} ${SIZE_HR}"
    echo -e "${BLUE}Files Copied:${NC} ${#COPIED_FILES[@]}"

    if [[ ${#COPIED_FILES[@]} -gt 0 ]]; then
        echo -e "\n${GREEN}Successfully copied:${NC}"
        for file in "${COPIED_FILES[@]}"; do
            echo "  - ${file}"
        done
    fi

    if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
        echo -e "\n${RED}Failed to copy:${NC}"
        for file in "${FAILED_FILES[@]}"; do
            echo "  - ${file}"
        done
    fi

    # Final status
    print_header "Backup Complete"
    if [[ ${#FAILED_FILES[@]} -eq 0 && ${#COPIED_FILES[@]} -gt 0 ]]; then
        print_success "All files backed up successfully!"
        return 0
    elif [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
        print_error "Some files failed to copy. Please review the errors above."
        return 1
    else
        print_warning "No files found to copy."
        return 1
    fi
}

# Run main function
main "$@"
