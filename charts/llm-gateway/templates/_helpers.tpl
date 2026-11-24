{{- define "llm-gateway.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "llm-gateway.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "llm-gateway.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: llm-gateway
{{ include "llm-gateway.selectorLabels" . }}
{{- end -}}

{{- define "llm-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "llm-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "llm-gateway.ollamaSelectorLabels" -}}
app.kubernetes.io/name: ollama
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "llm-gateway.secretName" -}}
{{- include "llm-gateway.fullname" . }}-keys
{{- end -}}

{{/*
gateway.json, with template expressions in values rendered. Expressions in
values must not contain double quotes: toPrettyJson escapes them, and tpl
then fails to parse the escaped string.
*/}}
{{- define "llm-gateway.config" -}}
{{- tpl (toPrettyJson .Values.config) . -}}
{{- end -}}

{{/* Kept to the release name so values.yaml can refer to it without quotes. */}}
{{- define "llm-gateway.ollamaName" -}}
{{- printf "%s-ollama" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
