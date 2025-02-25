{{/*
Deployment only labels
*/}}
{{- define "deployment_only_labels" -}}
app.kubernetes.io/component: spark-operator
app.kubernetes.io/technology: java
{{- end }}


{{/*
Deployment and service only labels
*/}}
{{- define "deployment_and_service_only_labels" -}}
name: {{ include "spark-operator.name" . }}
{{- end }}

{{/*
All object labels
*/}}
{{- define "all_objects_labels" -}}
app.kubernetes.io/part-of: spark-operator
{{- end }}

{{/*
Processed by grafana operator label
*/}}
{{- define "grafana_operator_label" -}}
app.kubernetes.io/processed-by-operator: grafana-operator
{{- end }}

{{/*
Processed by prometheus operator label
*/}}
{{- define "prometheus_operator_label" -}}
app.kubernetes.io/processed-by-operator: prometheus-operator
{{- end }}

{{/*
Processed by cert-manager label
*/}}
{{- define "cert_manager_label" -}}
app.kubernetes.io/processed-by-operator: cert-manager
{{- end }}
