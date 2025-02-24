{{/*
Expand the name of the chart.
*/}}
{{- define "spark-thrift-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "spark-thrift-server.fullname" -}}
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
{{- define "spark-thrift-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "spark-thrift-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "spark-thrift-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "spark-thrift-server.image" -}}
    {{ printf "%s:%s" (.Values.image.repository) (.Values.image.tag) }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "selector_labels_sts" -}}
app.kubernetes.io/instance: {{ cat .Release.Name "-" .Release.Namespace | nospace | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ template "spark-thrift-server.fullname" . }}
{{- end }}

{{/*
Deployment only labels
*/}}
{{- define "deployment_only_labels_sts" -}}
app.kubernetes.io/instance: {{ cat .Release.Name "-" .Release.Namespace | nospace | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/component: spark-thrift-server
app.kubernetes.io/version: {{ splitList ":" ( include "spark-thrift-server.image" . ) | last }}
app.kubernetes.io/technology: java
{{- end }}


{{/*
Deployment and service only labels
*/}}
{{- define "deployment_and_service_only_labels_sts" -}}
name: {{ template "spark-thrift-server.fullname" . }}
app.kubernetes.io/name: {{ template "spark-thrift-server.fullname" . }}
{{- end }}

{{/*
All object labels
*/}}
{{- define "all_objects_labels_sts" -}}
app.kubernetes.io/part-of: spark-operator
{{- end }}

{{/*
Processed by grafana operator label
*/}}
{{- define "grafana_operator_label_sts" -}}
app.kubernetes.io/processed-by-operator: grafana-operator
{{- end }}

{{/*
Processed by prometheus operator label
*/}}
{{- define "prometheus_operator_label_sts" -}}
app.kubernetes.io/processed-by-operator: prometheus-operator
{{- end }}

{{/*
Processed by cert-manager label
*/}}
{{- define "cert_manager_label_sts" -}}
app.kubernetes.io/processed-by-operator: cert-manager
{{- end }}