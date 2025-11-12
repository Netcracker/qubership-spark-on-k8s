{{/*
Expand the name of the chart.
*/}}
{{- define "spark-history-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "spark-history-server.fullname" -}}
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
{{- define "spark-history-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "spark-history-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "spark-history-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
History server replicas
*/}}
{{- define "spark-history-server-replicas" -}}
{{- if (.Values.replicas | int) }}
{{- printf "%s" .Values.replicas }}
{{- end }}
{{- end }}

{{- define "spark-history-server.image" -}}
    {{ printf "%s:%s" (.Values.image.repository) (.Values.image.tag) }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "selector_labels_shs" -}}
app.kubernetes.io/instance: {{ cat .Release.Name "-" .Release.Namespace | nospace | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ template "spark-history-server.fullname" . }}
{{- end }}

{{/*
Deployment only labels
*/}}
{{- define "deployment_only_labels_shs" -}}
app.kubernetes.io/instance: {{ cat .Release.Name "-" .Release.Namespace | nospace | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/component: spark-history-server
app.kubernetes.io/version: {{ splitList ":" ( include "spark-history-server.image" . ) | last }}
app.kubernetes.io/technology: java-others
{{- end }}


{{/*
Deployment and service only labels
*/}}
{{- define "deployment_and_service_only_labels_shs" -}}
name: {{ template "spark-history-server.fullname" . }}
app.kubernetes.io/name: {{ template "spark-history-server.fullname" . }}
{{- end }}

{{/*
All object labels
*/}}
{{- define "all_objects_labels_shs" -}}
{{ include "part_of_label_shs" . }}
{{- end }}

{{/*
Part of label
*/}}
{{- define "part_of_label_shs" -}}
app.kubernetes.io/part-of: spark-operator
{{- end }}

{{/*
Processed by grafana operator label
*/}}
{{- define "grafana_operator_label_shs" -}}
app.kubernetes.io/processed-by-operator: grafana-operator
{{- end }}

{{/*
Processed by prometheus operator label
*/}}
{{- define "prometheus_operator_label_shs" -}}
app.kubernetes.io/processed-by-operator: prometheus-operator
{{- end }}

{{/*
Processed by cert-manager label
*/}}
{{- define "cert_manager_label_shs" -}}
app.kubernetes.io/processed-by-operator: cert-manager
{{- end }}
