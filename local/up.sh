#!/usr/bin/env bash
# Run the gateway chart on a local kind cluster. Needs docker, kind, kubectl, helm.
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${GATEWAY_TAG:?set GATEWAY_TAG to a commit SHA of sillykea/llm-gateway}"
NS=llm-gateway

kind get clusters | grep -qx llm-gateway || kind create cluster --config local/kind.yaml
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

# Redis stands in for ElastiCache.
kubectl -n "$NS" apply -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata: { name: redis }
spec:
  selector: { matchLabels: { app: redis } }
  template:
    metadata: { labels: { app: redis } }
    spec:
      containers:
        - name: redis
          image: redis:7-alpine
          ports: [{ containerPort: 6379 }]
---
apiVersion: v1
kind: Service
metadata: { name: redis }
spec:
  selector: { app: redis }
  ports: [{ port: 6379 }]
YAML

# Stands in for the ExternalSecret that syncs from AWS Secrets Manager.
kubectl -n "$NS" create secret generic llm-gateway-keys \
  --from-literal=GATEWAY_API_KEY="${GATEWAY_API_KEY:-dev-key}" \
  --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY:-}" \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install llm-gateway charts/llm-gateway -n "$NS" \
  -f charts/llm-gateway/values-dev.yaml -f local/values-local.yaml \
  --set image.tag="$TAG" --wait --timeout 3m

echo
echo "Ready. In another terminal:"
echo "  kubectl -n $NS port-forward svc/llm-gateway 8080:80"
echo "  curl localhost:8080/v1/models -H 'Authorization: Bearer ${GATEWAY_API_KEY:-dev-key}'"
