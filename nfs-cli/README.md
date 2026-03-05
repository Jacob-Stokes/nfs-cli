# NearlyFreeSpeech Manager

Basic management tools for NearlyFreeSpeech.NET accounts via API.

## Structure

```
nfs-cli/
├── nfs-manager.sh          # Interactive menu interface
├── nfs-cli.sh              # Command-line interface
├── install.sh              # Optional installer for wrapper + credentials template
├── commands/               # Individual command scripts (interactive)
│   ├── nfs-account-info.sh
│   ├── nfs-dns.sh
│   ├── nfs-sites-list.sh
│   ├── nfs-domains.sh
│   ├── nfs-config.sh
│   └── nfs-help.sh
└── modules/               # Shared functionality
    ├── common.sh          # Authentication, utilities
    └── dns.sh            # DNS operations
```

## Installation (optional)

You can run the scripts in-place, or install a small wrapper that makes
`nfs-cli` available globally:

```bash
./install.sh
```

The installer will:

- create `~/.config/nfs/credentials` (if missing) and set permissions to 600;
- place a wrapper at `~/.local/bin/nfs-cli` (or the directory specified by
  `$NFS_INSTALL_BIN_DIR`);
- remind you to add the target directory to your `PATH` if required.

By default the wrapper launches the interactive manager. Set
`NFS_CLI_MODE=cli` to forward arguments straight to `nfs-cli.sh`:

```bash
NFS_CLI_MODE=cli nfs-cli dns --domain example.com --list
```

Additional installer environment overrides:

- `NFS_CREDENTIAL_FILE` – custom location for the credentials file.
- `NFS_INSTALL_BIN_DIR` – custom directory for the wrapper (`~/.local/bin` is
  the default).

## Usage

### Interactive Mode
```bash
./nfs-manager.sh           # Main menu interface
./commands/nfs-dns.sh      # DNS management only
```

### Command Line Mode
```bash
# DNS operations
./nfs-cli.sh dns --domain example.com --list
./nfs-cli.sh dns --domain example.com --add --name www --type A --data 1.2.3.4
./nfs-cli.sh dns --domain example.com --delete --name www --type A --data 1.2.3.4

# Account and sites
./nfs-cli.sh account --info
./nfs-cli.sh sites --list

# JSON output for automation
./nfs-cli.sh --json dns --domain example.com --list
./nfs-cli.sh --json sites | jq '.[0]'
```

## Setup

Credentials can be provided via:
1. Environment variables: `NFS_USERNAME`, `NFS_API_KEY`, `NFS_ACCOUNT_ID`
2. `.env` file in repository root
3. Interactive prompts (auto-discovers account ID)

## DNS Management

Supports both interactive menu and command-line operations:
- List all DNS records for a domain
- Add records (A, AAAA, CNAME, MX, TXT, etc.)
- Delete existing records
- Edit records (A, AAAA, TXT only)

Domain names can be saved and reused across sessions.

## Related

- [nfs-mcp](https://github.com/Jacob-Stokes/nfs-mcp) – MCP server exposing the same NearlyFreeSpeech.NET operations as tools for AI agents (Claude Desktop, etc.)

## Requirements

- curl
- jq
- openssl

