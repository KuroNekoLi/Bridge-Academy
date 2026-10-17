# syntax=docker/dockerfile:1
# STAGING PROTOTYPE ONLY — no public rollout approval.
FROM dart:stable AS dart-build
WORKDIR /source
COPY packages/bridge_core packages/bridge_core
COPY packages/bridge_ben_adapter packages/bridge_ben_adapter
COPY services/bridge_gateway services/bridge_gateway
WORKDIR /source/services/bridge_gateway
RUN dart pub get && dart compile exe bin/serve.dart -o /out/gateway

FROM ubuntu:24.04
ARG BEN_SHA=72653ec1b5c17116faea229e9b975ea5622aa1f7
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1 TF_CPP_MIN_LOG_LEVEL=2 CUDA_VISIBLE_DEVICES="" \
    OMP_NUM_THREADS=1 TF_NUM_INTRAOP_THREADS=1 TF_NUM_INTEROP_THREADS=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 python3-pip python3-venv python3-gdbm libboost-thread1.83.0 libicu74 \
    ca-certificates git nginx apache2-utils curl tini \
    && rm -rf /var/lib/apt/lists/*
RUN useradd --system --uid 10001 --create-home --shell /usr/sbin/nologin bridge
WORKDIR /opt
RUN git clone --filter=blob:none https://github.com/lorserker/ben.git ben \
    && cd ben && git checkout --detach "$BEN_SHA" \
    && test "$(git rev-parse HEAD)" = "$BEN_SHA"
RUN python3.12 -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir -r /opt/ben/requirements.txt
COPY --from=dart-build /out/gateway /usr/local/bin/bridge-gateway
COPY deploy/a4_5/zeabur/nginx.conf /etc/nginx/nginx.conf
COPY deploy/a4_5/zeabur/entrypoint.sh /usr/local/bin/a45-entrypoint
COPY deploy/a4_5/zeabur/healthcheck.sh /usr/local/bin/a45-healthcheck
RUN chmod 755 /usr/local/bin/a45-* /usr/local/bin/bridge-gateway \
    && mkdir -p /data/checkpoints /var/lib/nginx /var/log/nginx /run/nginx \
    && chown -R bridge:bridge /data /var/lib/nginx /var/log/nginx /run/nginx \
    && chmod 700 /data/checkpoints
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=8s --start-period=180s --retries=3 CMD ["/usr/local/bin/a45-healthcheck"]
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/a45-entrypoint"]
