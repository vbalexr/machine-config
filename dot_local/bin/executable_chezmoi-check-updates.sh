#!/usr/bin/env bash
# Checks the chezmoi source repo for new commits on the remote and, if any
# are found, pops a desktop notification offering to pull + apply them.
# Triggered on login and periodically by chezmoi-check-updates.timer.
set -euo pipefail

REPO="$HOME/.local/share/chezmoi"
TERMINAL="${CHEZMOI_UPDATE_TERMINAL:-alacritty -e}"

cd "$REPO"
git fetch origin --quiet

local_rev=$(git rev-parse @)
remote_rev=$(git rev-parse '@{u}')

if [ "$local_rev" = "$remote_rev" ]; then
  exit 0
fi

action=$(notify-send "chezmoi config" \
  "New changes on the remote — pull and apply now?" \
  -i software-update-available \
  -A "pull=Pull" -A "later=Later")

if [ "$action" = "pull" ]; then
  $TERMINAL bash -c 'chezmoi update --exclude=encrypted; echo; read -n1 -r -p "Press any key to close..."'
fi
