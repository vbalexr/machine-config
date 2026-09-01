# machine-config

Personal machine setup, managed with [chezmoi](https://www.chezmoi.io/), secured with a YubiKey (serial 24061473).

- **Secrets** are encrypted at rest with `age`, via `age-plugin-yubikey` — the private key never leaves the YubiKey's PIV slot 1, and decryption requires a physical touch.
- **SSH** uses a hardware-resident FIDO2 key (`ed25519-sk`, `verify-required`) — no SSH private key material is ever stored on disk or in this repo.
- A `gitleaks` pre-commit hook scans every commit for accidental plaintext secrets.

## Bootstrapping a new machine

1. Install tooling:
   ```
   sudo pacman -S --needed age chezmoi gitleaks pcsclite pcsc-tools libfido2 github-cli
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
   This also runs `run_once_after_ssh-bootstrap.sh.tmpl`, which calls `ssh-keygen -K` to re-download the resident SSH key's public stub from the YubiKey.
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
