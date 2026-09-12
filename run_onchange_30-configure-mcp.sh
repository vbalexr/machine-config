#!/usr/bin/env bash
# Registers MCP servers Claude Code should have in every project (user
# scope). `claude mcp add` errors on a duplicate, so this checks first.
set -euo pipefail

export NVM_DIR="${HOME}/.nvm"
for candidate in /usr/share/nvm/init-nvm.sh /usr/share/nvm/nvm.sh; do
  if [ -f "${candidate}" ]; then
    # shellcheck disable=SC1090
    source "${candidate}"
    break
  fi
done
nvm use default >/dev/null

if ! claude mcp get omnisql >/dev/null 2>&1; then
  echo "==> Registering omnisql MCP server (user scope)"
  claude mcp add --scope user omnisql -- omnisql-mcp
else
  echo "==> omnisql MCP server already registered"
fi

netbox_mcp_token_file="${HOME}/.claude/netbox-mcp-token"
if [ -f "${netbox_mcp_token_file}" ]; then
  # Re-register unconditionally so a rotated token in the token file is
  # always picked up -- `claude mcp add` errors on a duplicate name, so any
  # existing registration (possibly with a stale token) is removed first.
  if claude mcp get netbox >/dev/null 2>&1; then
    claude mcp remove --scope user netbox >/dev/null 2>&1
  fi
  echo "==> Registering netbox MCP server (user scope)"
  claude mcp add --scope user --transport http netbox http://10.1.0.4:8087/mcp \
    --header "Authorization: Bearer $(cat "${netbox_mcp_token_file}")"
else
  echo "==> Skipping netbox MCP server: ${netbox_mcp_token_file} not found (LAN-only, requires the NetBox box's homelab network)"
fi
