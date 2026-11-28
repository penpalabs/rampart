# shellcheck shell=bash
# 97-demo-user.sh — public demo only (demo/compose.demo.yaml sets
# DEMO_USER_EMAIL): a readonly login visitors can use. No-op otherwise.
if [ -n "${DEMO_USER_EMAIL:-}" ]; then
  if get /v1/users | jq -e --arg e "$DEMO_USER_EMAIL" '.[]|select(.email==$e)' >/dev/null 2>&1; then
    log "readonly demo user exists: $DEMO_USER_EMAIL"
  else
    r="$(post /v1/users "$(jq -nc --arg e "$DEMO_USER_EMAIL" --arg p "$DEMO_USER_PASSWORD" \
      '{email:$e,name:"Demo Viewer",password:$p,role:"readonly"}')")"
    if echo "$r" | jq -e '.id' >/dev/null 2>&1; then log "readonly demo user created: $DEMO_USER_EMAIL"
    else log "WARN: readonly demo user not created: $r"; fi
  fi
fi
