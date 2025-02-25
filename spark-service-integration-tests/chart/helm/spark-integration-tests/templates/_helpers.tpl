{{- define "spark-integration-tests.image" -}}
    {{- printf "%s" .Values.image -}}
{{- end -}}

{{/*
Get image for base applications
*/}}
{{- define "spark-base-application.image" -}}
    {{- printf "%s" .Values.sparkAppImage -}}
{{- end -}}

{{/*
Get image for python base applications
*/}}
{{- define "spark-py-base-application.image" -}}
    {{- printf "%s" .Values.sparkAppPyImage -}}
{{- end -}}

{{/*
Get Custom Resource apiGroup from path in Values
*/}}
{{- define "apigroup_custom_resource" -}}
{{- printf "%v" (index (regexSplit "/" .Values.cr_status_writing.status_custom_resource_path 5) 0) }}
{{- end -}}

{{/*
Get Custom Resource plural from path in Values
*/}}
{{- define "plural_custom_resource" -}}
{{- printf "%v" (index (regexSplit "/" .Values.cr_status_writing.status_custom_resource_path 5) 3) }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "selector_labels_ssit" -}}
app.kubernetes.io/instance: {{ cat .Release.Name "-" .Release.Namespace | nospace | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .Values.service.name }}
{{- end }}

{{/*
Deployment only labels
*/}}
{{- define "deployment_only_labels_ssit" -}}
app.kubernetes.io/instance: {{ cat .Release.Name "-" .Release.Namespace | nospace | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/component: spark-service-integration-tests
app.kubernetes.io/version: {{ splitList ":" ( include "spark-integration-tests.image" . ) | last | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/technology: python
{{- end }}


{{/*
Deployment and service only labels
*/}}
{{- define "deployment_and_service_only_labels_ssit" -}}
name: {{ .Values.service.name }}
app.kubernetes.io/name: {{ .Values.service.name }}
{{- end }}

{{/*
All object labels
*/}}
{{- define "all_objects_labels_ssit" -}}
app.kubernetes.io/part-of: spark-operator
{{- end }}

{{/*
Processed by grafana operator label
*/}}
{{- define "grafana_operator_label_ssit" -}}
app.kubernetes.io/processed-by-operator: grafana-operator
{{- end }}

{{/*
Processed by prometheus operator label
*/}}
{{- define "prometheus_operator_label_ssit" -}}
app.kubernetes.io/processed-by-operator: prometheus-operator
{{- end }}

{{/*
Processed by cert-manager label
*/}}
{{- define "cert_manager_label_ssit" -}}
app.kubernetes.io/processed-by-operator: cert-manager
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "spark-integration-tests.fullname" -}}
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