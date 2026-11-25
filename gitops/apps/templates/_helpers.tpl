{{/* Common Application settings: automated, self-healing, retried. */}}
{{- define "platform-apps.syncPolicy" -}}
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  retry:
    limit: 10
    backoff:
      duration: 10s
      factor: 2
      maxDuration: 5m
  syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
    # CRDs from another Application may not exist yet on the first sync.
    - SkipDryRunOnMissingResource=true
{{- end -}}

{{- define "platform-apps.destination" -}}
destination:
  server: https://kubernetes.default.svc
{{- end -}}


{{/* The console's internal key endpoint, which gateways poll. */}}
{{- define "platform-apps.consoleKeysUrl" -}}
http://llm-gateway-console.{{ .Values.console.namespace }}.svc:8091/internal/keys
{{- end -}}
