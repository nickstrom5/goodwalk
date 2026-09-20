#!/usr/bin/env bash
# One-shot Cloudflare setup for getgoodwalk.app: DNS for GitHub Pages + email forwarding.
# Idempotent: re-running skips anything that already exists.
#
# Usage:  bash scripts/cloudflare-setup.sh        (asks for the token; or pass CF_TOKEN=...)
# Token needs: Account:Email Routing Addresses:Edit, Zone:Email Routing Rules:Edit,
#              Zone:DNS:Edit, Zone:Zone:Read, scoped to getgoodwalk.app.
set -euo pipefail

DOMAIN="${DOMAIN:-getgoodwalk.app}"
FORWARD_TO="${FORWARD_TO:-Nickstrom5@gmail.com}"
GITHUB_USER="${GITHUB_USER:-nickstrom5}"
GITHUB_TXT_VALUE="${GITHUB_TXT_VALUE:-}"   # optional: value from github.com/settings/pages_verified_domains
API="https://api.cloudflare.com/client/v4"

case "${CF_TOKEN:-}" in ""|yourtoken|PASTE_TOKEN_HERE|"<token>")
  printf "Paste your Cloudflare API token and press Return (it will not show on screen): "
  read -rs CF_TOKEN; echo ;;
esac
[ "${#CF_TOKEN}" -ge 30 ] || { echo "That does not look like a Cloudflare token (too short). Nothing was changed."; exit 1; }
command -v jq >/dev/null || { echo "jq is required: brew install jq"; exit 1; }

cf() { # METHOD PATH [JSON]
  if [ $# -ge 3 ]; then
    curl -sS -X "$1" "$API$2" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" --data "$3"
  else
    curl -sS -X "$1" "$API$2" -H "Authorization: Bearer $CF_TOKEN"
  fi
}
ok() { jq -e '.success == true' >/dev/null; }

echo "▶ Verifying token"
cf GET /user/tokens/verify | jq -r '.result.status'

echo "▶ Finding zone $DOMAIN"
ZONE_JSON=$(cf GET "/zones?name=$DOMAIN")
ZONE_ID=$(echo "$ZONE_JSON" | jq -r '.result[0].id')
ACCOUNT_ID=$(echo "$ZONE_JSON" | jq -r '.result[0].account.id')
[ "$ZONE_ID" != "null" ] || { echo "Zone not found"; echo "$ZONE_JSON" | jq .; exit 1; }
echo "  zone $ZONE_ID  account $ACCOUNT_ID"

# ---------- DNS ----------
echo "▶ DNS records"
EXISTING=$(cf GET "/zones/$ZONE_ID/dns_records?per_page=200")

# Remove registrar parking records at the apex that would conflict with GitHub Pages.
echo "$EXISTING" | jq -r --arg d "$DOMAIN" '.result[] | select(.name == $d and (.type=="A" or .type=="AAAA" or .type=="CNAME")) | select(.type != "A" or (.content | startswith("185.199.") | not)) | "\(.id) \(.type) \(.content)"' | while read -r id type content; do
  echo "  removing conflicting apex record $type $content"
  cf DELETE "/zones/$ZONE_ID/dns_records/$id" | ok || echo "  (could not delete $id)"
done
EXISTING=$(cf GET "/zones/$ZONE_ID/dns_records?per_page=200")

ensure() { # TYPE NAME CONTENT
  if echo "$EXISTING" | jq -e --arg t "$1" --arg n "$2" --arg c "$3" '.result[] | select(.type==$t and .name==$n and .content==$c)' >/dev/null; then
    echo "  exists   $1 $2 -> $3"
  else
    cf POST "/zones/$ZONE_ID/dns_records" "$(jq -nc --arg t "$1" --arg n "$2" --arg c "$3" '{type:$t,name:$n,content:$c,ttl:1,proxied:false}')" | ok \
      && echo "  created  $1 $2 -> $3" || echo "  FAILED   $1 $2 -> $3"
  fi
}
for ip in 185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153; do ensure A "$DOMAIN" "$ip"; done
ensure CNAME "www.$DOMAIN" "$GITHUB_USER.github.io"
if [ -n "$GITHUB_TXT_VALUE" ] && [ "${GITHUB_TXT_VALUE#value_for}" = "$GITHUB_TXT_VALUE" ]; then
  ensure TXT "_github-pages-challenge-$GITHUB_USER.$DOMAIN" "$GITHUB_TXT_VALUE"
else
  echo "  skipped  GitHub verification TXT (optional; the site works without it)"
fi

# ---------- Email routing ----------
echo "▶ Email routing"
cf POST "/zones/$ZONE_ID/email/routing/enable" | ok && echo "  enabled (MX/TXT records added by Cloudflare)" || echo "  enable: already on or not permitted (continuing)"

if cf GET "/accounts/$ACCOUNT_ID/email/routing/addresses?per_page=50" | jq -e --arg e "$FORWARD_TO" '.result[] | select(.email==$e)' >/dev/null; then
  echo "  destination exists: $FORWARD_TO"
else
  cf POST "/accounts/$ACCOUNT_ID/email/routing/addresses" "$(jq -nc --arg e "$FORWARD_TO" '{email:$e}')" | ok \
    && echo "  destination added: $FORWARD_TO  → check that inbox for Cloudflare's verification email" || echo "  FAILED adding destination"
fi

RULES=$(cf GET "/zones/$ZONE_ID/email/routing/rules?per_page=50")
for addr in "support@$DOMAIN" "hello@$DOMAIN"; do
  if echo "$RULES" | jq -e --arg a "$addr" '.result[] | select(.matchers[]?.value==$a)' >/dev/null; then
    echo "  rule exists: $addr"
  else
    cf POST "/zones/$ZONE_ID/email/routing/rules" "$(jq -nc --arg a "$addr" --arg to "$FORWARD_TO" '{name:("Forward "+$a),enabled:true,matchers:[{type:"literal",field:"to",value:$a}],actions:[{type:"forward",value:[$to]}]}')" | ok \
      && echo "  rule created: $addr → $FORWARD_TO" || echo "  FAILED rule $addr"
  fi
done

cf PUT "/zones/$ZONE_ID/email/routing/rules/catch_all" "$(jq -nc --arg to "$FORWARD_TO" '{name:"Catch-all",enabled:true,matchers:[{type:"all"}],actions:[{type:"forward",value:[$to]}]}')" | ok \
  && echo "  catch-all → $FORWARD_TO" || echo "  FAILED catch-all"

echo
echo "Done. Next:"
echo "  1. Click the verification link Cloudflare emailed to $FORWARD_TO (forwarding is inactive until then)."
echo "  2. GitHub → Settings → Pages → verified domains → Verify."
echo "  3. Repo Settings → Pages → custom domain $DOMAIN → Enforce HTTPS once the check passes."
echo "  4. Delete the goodwalk-setup API token in Cloudflare."
