{{- define "qubership-spark-on-k8s.spark-operator.fullname" -}}
{{- if index .Values "spark-operator" "fullnameOverride" -}}
{{- index .Values "spark-operator" "fullnameOverride" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "spark-operator" (index .Values "spark-operator" "nameOverride") -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "qubership-spark-on-k8s.spark-operator.controller.name" -}}
{{- include "qubership-spark-on-k8s.spark-operator.fullname" . }}-controller
{{- end -}}

{{- define "qubership-spark-on-k8s.spark-operator.webhook.name" -}}
{{- include "qubership-spark-on-k8s.spark-operator.fullname" . }}-webhook
{{- end -}}


{{- define "qubership-spark-on-k8s.spark-operator.controller.deploymentName" -}}
{{ include "qubership-spark-on-k8s.spark-operator.controller.name" . }}
{{- end -}}


{{- define "qubership-spark-on-k8s.spark-operator.webhook.deploymentName" -}}
{{ include "qubership-spark-on-k8s.spark-operator.webhook.name" . }}
{{- end -}}


{{/*
Calculates resources that should be monitored during deployment by Deployment Status Provisioner.
*/}}
{{- define "spark.monitoredResources" -}}
  {{- if (index .Values "spark-operator" "controller" "replicas" | int) }}
  {{- printf "Deployment %s, " (include "qubership-spark-on-k8s.spark-operator.controller.deploymentName" .) -}}
  {{- end }}
  {{- if index .Values "spark-operator" "webhook" "enable" }}
  {{- if (index .Values "spark-operator" "webhook" "replicas" | int) }}
  {{- printf "Deployment %s, " (include "qubership-spark-on-k8s.spark-operator.webhook.deploymentName" .) -}}
  {{- end }}
  {{- end }}
  {{- if index .Values "spark-history-server" "enabled" }}
  {{- $replicas := (include "spark-history-server-replicas" (set (deepCopy .) "Values" (index .Values "spark-history-server")) | int) -}}
  {{- if ($replicas) }}
  {{- printf "Deployment %s, " (include "spark-history-server.fullname" (set (deepCopy .) "Values" (index .Values "spark-history-server"))) }}
  {{- end }}
  {{- end }}
  {{- if index .Values "spark-thrift-server" "enabled" }}
  {{- printf "StatefulSet %s, " (include "spark-thrift-server.fullname" (set (deepCopy .) "Values" (index .Values "spark-thrift-server"))) }}
  {{- end }}
  {{- if index .Values "spark-integration-tests" "enabled" }}
  {{- printf "Deployment spark-integration-tests-runner, " -}}
  {{- end }}
{{- end -}}


{{/*
Find a Deployment Status Provisioner image in various places.
*/}}
{{- define "deployment-status-provisioner.image" -}}
    {{- printf "%s" .Values.statusProvisioner.image -}}
{{- end -}}