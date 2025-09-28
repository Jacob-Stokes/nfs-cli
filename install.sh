#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BIN_DIR="${HOME}/.local/bin"
DEFAULT_CREDENTIAL_FILE="${HOME}/.config/nfs/credentials"
WRAPPER_NAME="nfs-cli"

# Print helper
print_step() {
    printf '\n==> %s\n' "$1"
}

# Simple yes/no prompt
ask_yes_no() {
    local prompt="$1"
    local default_answer="${2:-n}"
    local reply
    read -r -p "$prompt [y/N]: " reply
    reply=${reply:-$default_answer}
    [[ "$reply" =~ ^[Yy]$ ]]
}

ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        printf 'Created %s\n' "$dir"
    fi
}

create_credentials_template() {
    local cred_file="$1"
    ensure_directory "$(dirname "$cred_file")"
    if [[ -f "$cred_file" ]]; then
        printf 'Credentials file already exists at %s\n' "$cred_file"
    else
        cat <<'TEMPLATE' > "$cred_file"
# NearlyFreeSpeech credentials (keep this file private)
export NFS_USERNAME="your_username"
export NFS_API_KEY="your_api_key"
export NFS_ACCOUNT_ID="your_account_id"
# Optional defaults
# export DEFAULT_DOMAIN="example.com"
# export DEFAULT_TTL=3600
TEMPLATE
        chmod 600 "$cred_file"
        printf 'Created credentials template at %s (chmod 600)\n' "$cred_file"
    fi
}

install_wrapper() {
    local bin_dir="$1"
    local cred_file="$2"
    ensure_directory "$bin_dir"

    local wrapper_path="$bin_dir/$WRAPPER_NAME"
    if [[ -e "$wrapper_path" ]]; then
        if ! ask_yes_no "Wrapper $wrapper_path exists. Overwrite?" "n"; then
            printf 'Skipped wrapper installation.\n'
            return
        fi
    fi

    cat <<EOF > "$wrapper_path"
#!/usr/bin/env bash
set -euo pipefail

CREDENTIAL_FILE="${cred_file}"
MANAGER_ROOT="${PROJECT_ROOT}"
MANAGER_SCRIPT="${PROJECT_ROOT}/nfs-manager.sh"
CLI_SCRIPT="${PROJECT_ROOT}/nfs-cli.sh"

if [[ -f "\${NFS_CLI_CREDENTIAL_FILE:-\$CREDENTIAL_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "\${NFS_CLI_CREDENTIAL_FILE:-\$CREDENTIAL_FILE}"
fi

if [[ -n "\${NFS_CLI_MODE:-}" ]]; then
  MODE="\${NFS_CLI_MODE}"
else
  MODE="interactive"
fi

case "\${MODE}" in
  interactive)
    exec "\${NFS_CLI_SCRIPT:-\$MANAGER_SCRIPT}" "\$@"
    ;;
  cli)
    exec "\${NFS_CLI_SCRIPT:-\$CLI_SCRIPT}" "\$@"
    ;;
  *)
    echo "[nfs-cli] Unknown mode \$MODE" >&2
    exit 1
    ;;
esac
EOF

    chmod +x "$wrapper_path"
    printf 'Installed wrapper to %s\n' "$wrapper_path"
}

check_path() {
    local bin_dir="$1"
    IFS=':' read -ra path_entries <<< "$PATH"
    for entry in "${path_entries[@]}"; do
        if [[ "$entry" == "$bin_dir" ]]; then
            return 0
        fi
    done
    printf '\n[Notice] %s is not on your PATH. Add the following line to your shell profile:\n' "$bin_dir"
    printf '  export PATH="%s:$PATH"\n' "$bin_dir"
}

main() {
    local bin_dir="${NFS_INSTALL_BIN_DIR:-$DEFAULT_BIN_DIR}"
    local cred_file="${NFS_CREDENTIAL_FILE:-$DEFAULT_CREDENTIAL_FILE}"

    print_step "Installing NearlyFreeSpeech CLI"
    printf 'Project root: %s\n' "$PROJECT_ROOT"
    printf 'Binary target: %s\n' "$bin_dir"
    printf 'Credentials file: %s\n' "$cred_file"

    create_credentials_template "$cred_file"
    install_wrapper "$bin_dir" "$cred_file"
    check_path "$bin_dir"

    print_step 'Done'
    cat <<'INFO'
You can now run the CLI with:
  nfs-cli

Set NFS_CLI_MODE=cli to forward arguments to nfs-cli.sh, e.g.
  NFS_CLI_MODE=cli nfs-cli dns --domain example.com --list
INFO
}

main "$@"
