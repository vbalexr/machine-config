# machine-config

Personal machine setup, managed with [chezmoi](https://www.chezmoi.io/), secured with a YubiKey (serial 24061473).

- **Secrets** (including the SSH private key below) are encrypted at rest with `age`, via `age-plugin-yubikey` — the age identity's private key never leaves the YubiKey's PIV slot 1, and decryption requires a physical touch.
- **SSH** is a normal software `ed25519` key. It is stored in this repo only in its `age`-encrypted form; `chezmoi apply` decrypts it to `~/.ssh/id_ed25519_personal` on each machine (one YubiKey touch at that point). After that, day-to-day SSH use on that machine needs no YubiKey, no touch, no PIN — a deliberate trade-off for daily convenience. This means the decrypted private key on disk is usable by anything running as your user on that machine; treat any machine you `chezmoi apply` this to as trusted.
- A `gitleaks` pre-commit hook scans every commit for accidental plaintext secrets.
- **If the SSH private key is ever exposed** (e.g. pasted somewhere, printed to a shared terminal): treat it as compromised immediately — `gh ssh-key delete <id>`, delete `~/.ssh/id_ed25519_personal*`, regenerate with `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -N ""`, `gh ssh-key add ~/.ssh/id_ed25519_personal.pub`, then `chezmoi add --encrypt ~/.ssh/id_ed25519_personal` and commit. Exposure in a place you don't fully control (chat transcripts, logs, screen shares) counts, even if you don't know for sure anyone else saw it.

## Bootstrapping a new machine

1. Install the minimum needed to bootstrap chezmoi itself (everything else in `.chezmoidata/packages.yaml`, including `gitleaks`, `nvm`, and `dbeaver`, is installed automatically in step 3 by `run_onchange_00-install-packages.sh`):
   ```
   sudo pacman -S --needed age chezmoi pcsclite pcsc-tools libfido2 github-cli
   sudo systemctl enable --now pcscd
   paru -S age-plugin-yubikey yubikey-manager
   ```
2. Plug in the YubiKey. Re-derive the local age identity stub (safe to regenerate — it's a pointer to the on-device key, not the key itself):
   ```
   mkdir -p ~/.config/chezmoi
   age-plugin-yubikey --identity > ~/.config/chezmoi/age-yubikey-identity.txt
   chmod 600 ~/.config/chezmoi/age-yubikey-identity.txt
   ```
3. Initialize and apply:
   ```
   chezmoi init --apply git@github.com:vbalexr/machine-config.git
   ```
   This decrypts `~/.ssh/id_ed25519_personal` (one YubiKey PIN + touch during apply) along with the plain config files, then runs the `run_onchange_*` scripts in order: installs the rest of the packages, sets up a pacman-packaged `nvm` with the current Node LTS (so `npm install -g` never needs `sudo`), installs the npm globals in `.chezmoidata/packages.yaml`, and registers the MCP servers Claude Code should always have (currently `omnisql`, for reaching your SQL servers). A brand-new MCP registration only appears in *new* Claude Code sessions started after the apply — restart any sessions already running.
4. Activate the gitleaks pre-commit hook (not carried by `git config`, must be set per clone):
   ```
   cd ~/.local/share/chezmoi && git config core.hooksPath .githooks
   ```
5. Verify:
   ```
   chezmoi diff
   ssh -T git@github.com
   gitleaks detect --source ~/.local/share/chezmoi
   ```

## Adding new secrets

```
chezmoi add --encrypt <path>
```
Decrypting on `chezmoi apply` will prompt for a YubiKey touch.

## Dependencies (packages, npm globals, MCP servers)

`.chezmoidata/packages.yaml` is the single declarative list: `packages.pacman`, `packages.aur`, and `npm_globals`. Add a name, `chezmoi apply`, done — the `run_onchange_*` scripts pick up the change automatically (chezmoi re-runs a `run_onchange_` script whenever its *rendered* contents change, and these scripts template directly off that file). MCP servers are registered by `run_onchange_30-configure-mcp.sh`; add a new one there following the same "check with `claude mcp get`, then `claude mcp add --scope user`" pattern.

**omnisql MCP + DBeaver**: `omnisql-mcp` gives Claude Code read/write access to your SQL servers, but it doesn't take connection strings itself — it reads whatever connections are already saved in a local DBeaver-compatible workspace (that's why `dbeaver` is in the pacman list). This repo does **not** sync your DBeaver connections/credentials — set those up per machine in DBeaver itself. Before relying on this, check where DBeaver stores saved passwords on this machine (its workspace, typically under `~/.local/share/DBeaverData`) and whether they're encrypted at rest; if they're plaintext, that store should not be added to this repo without the same `chezmoi add --encrypt` treatment the SSH key gets, and DBeaver has a "use master password to encrypt local credentials" option worth turning on regardless. `omnisql-mcp` also supports `OMNISQL_READ_ONLY=true` and `OMNISQL_ALLOWED_CONNECTIONS` env vars if you want to scope down what Claude can touch — not set by default.
