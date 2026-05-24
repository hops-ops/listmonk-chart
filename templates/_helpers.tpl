{{/*
Expand the name of the chart.
*/}}
{{- define "listmonk.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "listmonk.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "listmonk.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "listmonk.labels" -}}
helm.sh/chart: {{ include "listmonk.chart" . }}
{{ include "listmonk.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "listmonk.selectorLabels" -}}
app.kubernetes.io/name: {{ include "listmonk.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "listmonk.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "listmonk.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get database password secret name
*/}}
{{- define "listmonk.dbSecretName" -}}
{{- if .Values.database.existingSecret }}
{{- .Values.database.existingSecret }}
{{- else }}
{{- printf "%s-db" (include "listmonk.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get SMTP secret name
*/}}
{{- define "listmonk.smtpSecretName" -}}
{{- if .Values.smtp.existingSecret }}
{{- .Values.smtp.existingSecret }}
{{- else }}
{{- printf "%s-smtp" (include "listmonk.fullname" .) }}
{{- end }}
{{- end }}

{{/*
PostgreSQL StatefulSet name (single source of truth for PVC naming).
Do not change nameOverride after first install or PVC will be orphaned.
*/}}
{{- define "listmonk.postgresStatefulSetName" -}}
{{- printf "%s-postgres" (include "listmonk.name" .) }}
{{- end }}

{{/*
Secret name written by the api-user-bootstrap hook. Carries the
crossplane-provider api credential keys: username + token.
Override via .Values.adminAuth.secretName when integrating with
externally-managed Secret stores.
*/}}
{{- define "listmonk.providerCredsSecretName" -}}
{{- if .Values.adminAuth.secretName }}
{{- .Values.adminAuth.secretName }}
{{- else }}
{{- printf "%s-provider-creds" (include "listmonk.fullname" .) }}
{{- end }}
{{- end }}
