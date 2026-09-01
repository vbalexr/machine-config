# machine-config

Personal machine setup, managed with [chezmoi](https://www.chezmoi.io/), secured with a YubiKey (serial 24061473).

- **Secrets** (including the SSH private key below) are encrypted at rest with `age`, via `age-plugin-yubikey` — the age identity's private key never leaves the YubiKey's PIV slot 1, and decryption requires a physical touch.
- **SSH** is a normal software `ed25519` key. It is stored in this repo only in its `age`-encrypted form; `chezmoi apply` decrypts it to `~/.ssh/id_ed25519_personal` on each machine (one YubiKey touch at that point). After that, day-to-day SSH use on that machine needs no YubiKey, no touch, no PIN — a deliberate trade-off for daily convenience. This means the decrypted private key on disk is usable by anything running as your user on that machine; treat any machine you `chezmoi apply` this to as trusted.
- A `gitleaks` pre-commit hook scans every commit for accidental plaintext secrets.
- **If the SSH private key is ever exposed** (e.g. pasted somewhere, printed to a shared terminal): treat it as compromised immediately — `gh ssh-key delete <id>`, delete `~/.ssh/id_ed25519_personal*`, regenerate with `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -N ""`, `gh ssh-key add ~/.ssh/id_ed25519_personal.pub`, then `chezmoi add --encrypt ~/.ssh/id_ed25519_personal` and commit. Exposure in a place you don't fully control (chat transcripts, logs, screen shares) counts, even if you don't know for sure anyone else saw it.

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
   This decrypts `~/.ssh/id_ed25519_personal` (one YubiKey PIN + touch during apply) along with the plain config files.
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
