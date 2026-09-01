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
