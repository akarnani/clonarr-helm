{{/*
Chart name, truncated to 63 chars.
*/}}
{{- define "clonarr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name.
*/}}
{{- define "clonarr.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "clonarr.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "clonarr.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "clonarr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clonarr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve the image reference. Uses digest if set, otherwise tag.
Rancher Desktop on Apple Silicon uses Rosetta (x86_64), so default to amd64.
*/}}
{{- define "clonarr.image" -}}
{{- if .Values.image.digest }}
{{- if .Values.image.digest.amd64 }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest.amd64 }}
{{- else if .Values.image.digest.arm64 }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest.arm64 }}
{{- else }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest }}
{{- end }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}
{{- end }}
