# A4.5.2 — Zeabur single-container staging (NOT deployed)

## Resource assumption
Owner permits planning for **2 vCPU, 4 GB RAM, 20 GB+ free disk**, with no additional hosting fees. These are assumptions, not recorded real capacity or BEN RSS. The image build/download may itself exceed this budget. Docker runtime requires **Linux amd64** (BEN's pinned vendored dds3 binary and native deps); ARM support is not claimed. Confirm image architecture before deploy.

## Build (do not upload secret files)
Run at repo root:
```bash
docker build --platform linux/amd64 -f deploy/a4_5/zeabur/Dockerfile -t bridge-academy:staging .
```
Build pulls **exact** BEN commit `72653ec1b5c17116faea229e9b975ea5622aa1f7`. Note: BEN's pinned model paths and native DDS library must be verified by genuine BEN readiness; a green Docker build is insufficient. This first prototype is intentionally not yet optimized for image size.

## Secret setup (private environment; NEVER commit)
Generate a random 32-byte base64 key once and store in a Zeabur secret manager. Persistent encrypted archive must keep the same key across restarts:
```bash
openssl rand -base64 32
htpasswd -nbB staging-user '<strong-random-password>' > /private/staging_htpasswd
```
Do not put password inline in a shared shell history, CI, Docker layers or chat; above command is a format illustration only. Use interactive `htpasswd -cB /private/staging_htpasswd staging-user` to avoid shell history. Make this file available **inside container at `/run/secrets/staging_htpasswd`**, readable by nginx. Must be private read-only mounted file or equivalent; env vars are not a substitute for the mounted file. Set `STAGING_BASIC_AUTH_FILE=/run/secrets/staging_htpasswd` (the current nginx configuration uses this exact fixed path), `GATEWAY_CHECKPOINT_KEY_B64`, and `GATEWAY_BROWSER_ORIGINS=https://YOUR-STAGING-DOMAIN`. Forbid real tokens in `BRIDGE_GATEWAY_ORIGIN` compiled frontend bundle.

Attach a persistent volume at `/data/checkpoints`, restricted to this service, to preserve AES-GCM archives. Ensure it remains owned by container runtime user or has correct permissions before startup. Staging storage cost needs verification. **Do not deploy if Zeabur cannot mount the private htpasswd file without baking a password into image.**

## Ports / ingress
Zeabur maps the web domain HTTPS to **container port 8080**, the **only** public port. nginx is a staging Basic Auth barrier. Dart Gateway is at `127.0.0.1:8086`; BEN is `127.0.0.1:8085`, with no public port mapping. `/healthz` on :8080 is proxy-only and cannot prove model readiness; use container healthcheck to probe all three.

Note browser Basic Auth on the proxy can complicate first-party cross-origin Flutter Web; prefer serving the Flutter Web assets on the same HTTPS host in a later integration, or verify CORS/preflight and browser credentials before claiming E2E. **Current Docker image only exposes the private Gateway and does not serve the Flutter bundle.**

## Validation order
1. CI static checks, `docker build`, container startup, three internal readiness checks and exit-on-crash; inspect memory RSS and image disk size.
2. Auth required on real non-health endpoints, anti-leak tests and raw `/v1/ai/decision` disabled in encrypted mode.
3. Run trusted fixture through HTTPS edge + private real BEN. 4+ completed boards, p50/p95/p99 / memory / retries, and volume restart check.
4. Approval of BEN source/model/weights/DDS service rights, cost/volume billing, proxy safety, key rotation and rollback BEFORE any public exposure.

**Status:** CONFIGURATION AND SOURCE PREPARED, not Docker-built, Zeabur-deployed, real-BEN resource-tested or publicly accessible. `master` is unchanged.
