{{/* Chart name */}}
{{- define "web-nginx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/* Chart release */}}
{{- define "web-nginx.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "web-nginx.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}
{{- end }}

{{/* Common labels */}}
{{- define "web-nginx.labels" -}}
app.kubernetes.io/name: {{ include "web-nginx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "web-nginx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "web-nginx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end }}

{{/* Back-compat shim for old templates */}}
{{- define "web.labels" -}}
{{ include "web-nginx.labels" . }}
{{- end }}
