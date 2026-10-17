#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
: "${GATEWAY_CHECKPOINT_KEY_B64:?External 32-byte encryption key required}"
: "${GATEWAY_BROWSER_ORIGINS:?Explicit HTTPS browser Origin required}"
: "${STAGING_BASIC_AUTH_FILE:?Private htpasswd file path required}"
[[ "${GATEWAY_BROWSER_ORIGINS}" =~ ^https://[a-zA-Z0-9.-]+(:[0-9]{1,5})?$ ]] || { echo 'Exactly one HTTPS origin with no path, wildcard or insecure fallback required' >&2; exit 64; }
[[ "${STAGING_BASIC_AUTH_FILE}" == /run/secrets/staging_htpasswd ]] || { echo 'htpasswd path must match nginx.conf' >&2; exit 64; }
[[ -s "${STAGING_BASIC_AUTH_FILE}" ]] || { echo 'Missing nonempty htpasswd file' >&2; exit 64; }
# The nginx worker, not only the root entrypoint, must be able to read the secret.
runuser -u www-data -- test -r "${STAGING_BASIC_AUTH_FILE}" || { echo 'nginx worker cannot read htpasswd' >&2; exit 64; }
[[ -f /opt/ben/src/gameapi.py ]] || { echo 'BEN missing' >&2; exit 78; }
[[ -d /data/checkpoints ]] || { echo 'Checkpoint volume missing' >&2; exit 78; }
chmod 700 /data/checkpoints
export BEN_INTERNAL_ORIGIN=http://127.0.0.1:8085
export GATEWAY_CHECKPOINT_DIR=/data/checkpoints
export GATEWAY_PORT=8086
# No dev quota override, no public Gateway bind.
cp /opt/ben/src/config/default_api.conf /tmp/ben-staging.conf
python3.12 - <<'PY'
from pathlib import Path
p=Path('/tmp/ben-staging.conf')
data=p.read_text()
for key, value in {
    'consult_bba': 'False','use_bba_rollout':'False',
    'use_bba_to_count_aces':'False','pimc_use_declaring':'False',
    'pimc_use_defending':'False','pimc_use_discarding':'False',
}.items():
    import re
    data,n=re.subn(r'(?m)^('+re.escape(key)+r'\s*=\s*)\w+',lambda m:m.group(1)+value,data)
    if n == 0: raise SystemExit('BEN config drift: '+key)
p.write_text(data)
PY
chmod 600 /tmp/ben-staging.conf
children=()
shutdown() {
  trap - TERM INT
  for pid in "${children[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
  wait || true
}
trap shutdown TERM INT EXIT
cd /opt/ben/src
/opt/venv/bin/python gameapi.py --config /tmp/ben-staging.conf \
  --host 127.0.0.1 --allowed-hosts 127.0.0.1,localhost \
  --record false --verbose false > /dev/null 2>&1 &
children+=("$!")
/usr/local/bin/bridge-gateway > /dev/null 2>&1 &
children+=("$!")
# Never start public proxy until the private dependencies respond.
for _ in $(seq 1 120); do
  if curl --fail --silent --max-time 2 http://127.0.0.1:8085/ >/dev/null &&
     curl --fail --silent --max-time 2 http://127.0.0.1:8086/healthz >/dev/null; then
    break
  fi
  for pid in "${children[@]}"; do
    if ! kill -0 "$pid" 2>/dev/null; then echo 'Private service exited' >&2; exit 78; fi
  done
  sleep 2
done
curl --fail --silent --max-time 2 http://127.0.0.1:8085/ >/dev/null ||
  { echo 'BEN failed readiness' >&2; exit 78; }
curl --fail --silent --max-time 2 http://127.0.0.1:8086/healthz >/dev/null ||
  { echo 'Gateway failed readiness' >&2; exit 78; }
# nginx worker must read private htpasswd path; configured proxy remains staging-only.
nginx -g 'daemon off;' &
children+=("$!")
wait -n "${children[@]}" || true
echo 'Service exited; stopping staging container' >&2
exit 1
