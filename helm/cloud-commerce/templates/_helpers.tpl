{{/*
Return the chart name.
*/}}
{{- define "cloud-commerce.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return the fully qualified release name.
*/}}
{{- define "cloud-commerce.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "cloud-commerce.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "cloud-commerce.labels" -}}
app.kubernetes.io/name: {{ include "cloud-commerce.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "cloud-commerce.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cloud-commerce.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}