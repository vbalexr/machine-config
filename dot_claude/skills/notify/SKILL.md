---
name: notify
description: Push a message to the user's Discord via their configured webhook. Use whenever the user asks to be notified, pinged, or to "push"/"send" a notification — the built-in PushNotification tool can't reach them since mobile push is disabled for this user.
user-invocable: true
allowed-tools:
  - Bash(curl *)
---

# /notify — Discord notification

Sends a message to the user's Discord via the webhook they already have
configured. This is the reliable notification path for this user: the
built-in `PushNotification` tool only supports desktop + mobile push, and
mobile push is disabled in their `/config`.

Arguments passed: `$ARGUMENTS` — the message to send. If empty, ask the user
what to send, or summarize what just happened/finished if that's the clear
intent (e.g. "notify me when done" earlier in the conversation).

## Steps

1. Post the message in a single command. Never `cat` the webhook file on its
   own or print it — read it only via inline command substitution inside the
   curl call, so the raw URL never appears in your output or the transcript:
   ```
   [ -s ~/.claude/discord_webhook_url ] && curl -s -o /dev/null -w '%{http_code}' \
     -X POST -H 'Content-Type: application/json' \
     -d "$(jq -Rn --arg c "<message>" '{content: $c}')" \
     "$(cat ~/.claude/discord_webhook_url)" || echo "MISSING_WEBHOOK"
   ```
   `204` means success. If you see `MISSING_WEBHOOK`, tell the user and stop
   — don't guess a URL.
2. Confirm briefly to the user that it was sent.

## Notes

- Keep messages short and lead with the actionable part, same as any
  notification — what they'd want to know at a glance.
- Also fine to call `PushNotification` alongside this for the desktop-notify
  side effect, but don't rely on it alone for delivery.
- The webhook file contains a secret. Never read it with a bare `Read` or
  `cat` call, never echo it, and never paste it into a message to the user —
  only ever use it inline inside the curl command as shown above.
- `~/.claude/discord-notify.sh` exists on disk but is unused/stale — don't
  invoke it. The automatic Notification hook that used to also curl this
  webhook has been removed; this skill is now the only path that sends to
  Discord.
