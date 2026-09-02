#!/usr/bin/env bash
# Claude Code Notification hook: posts a brief of what Claude is doing,
# and why it's blocked/waiting, to a Discord webhook.

input=$(cat)
msg=$(jq -r '.message // "Claude notification"' <<<"$input" 2>/dev/null)
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
tpath=$(jq -r '.transcript_path // empty' <<<"$input" 2>/dev/null)

proj=$(basename "${cwd:-session}" 2>/dev/null)
[ -n "$proj" ] || proj="session"

brief=""
if [ -n "$tpath" ] && [ -f "$tpath" ]; then
  brief=$(tac "$tpath" 2>/dev/null \
    | jq -r 'select(.type=="assistant") | ([.message.content[]? | select(.type=="text") | .text] | join(" "))' 2>/dev/null \
    | grep -v '^[[:space:]]*$' 2>/dev/null \
    | head -n1 \
    | cut -c1-300)
fi

content="**${proj}** — ${msg:-Claude notification}"
if [ -n "$brief" ]; then
  content="${content}
> ${brief}"
fi

url_file="$HOME/.claude/discord_webhook_url"
if [ -f "$url_file" ]; then
  url=$(cat "$url_file")
  if [ -n "$url" ]; then
    payload=$(jq -n --arg c "$content" '{content: $c}')
    curl -s -X POST -H 'Content-Type: application/json' -d "$payload" "$url" >/dev/null 2>&1
  fi
fi

exit 0
