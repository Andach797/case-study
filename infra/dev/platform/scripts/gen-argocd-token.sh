#!/usr/bin/env sh
set -eu                                    # dash-compatible

PW_B64="$1"
PW="$(printf '%s' "$PW_B64" | base64 -d)"

TOKEN="$(kubectl -n argocd exec deploy/argocd-repo-server -- \
  sh -c "argocd --grpc-web --insecure \
    --server argocd-server.argocd.svc.cluster.local:443 \
    login --username admin --password '${PW}' --plaintext >/dev/null && \
    argocd account generate-token --account admin")"

kubectl -n argocd patch secret argocd-image-updater-secret \
  --type merge \
  --patch "$(printf '{"data":{"argocd.token":"%s"}}' \
            "$(printf '%s' "$TOKEN" | base64 -w0)")"
