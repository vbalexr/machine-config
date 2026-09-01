#!/usr/bin/env bash
# Installs the current Node LTS via nvm (packaged by pacman, see
# .chezmoidata/packages.yaml) and pins it as the default.
set -euo pipefail

export NVM_DIR="${HOME}/.nvm"
mkdir -p "${NVM_DIR}"

nvm_init=""
for candidate in /usr/share/nvm/init-nvm.sh /usr/share/nvm/nvm.sh; do
  if [ -f "${candidate}" ]; then
    nvm_init="${candidate}"
    break
  fi
done
if [ -z "${nvm_init}" ]; then
  echo "nvm.sh not found; is the 'nvm' pacman package installed?" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "${nvm_init}"

nvm install --lts
nvm alias default "$(nvm current)"
