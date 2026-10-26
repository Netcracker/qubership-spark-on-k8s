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
Whether to render the legacy Ingress resource. Uses .Values.ingress.enabled when explicitly set
(true/false); otherwise falls back to whether GATEWAY_SYSTEM_TYPE contains "legacy-ingress",
or, when GATEWAY_SYSTEM_TYPE is not set, to whether Gateway API CRDs are NOT available in
 the cluster.
*/}}
{{- define "spark-history-server.ingressEnabled" -}}
{{- if eq .Values.ingress.enabled nil -}}
{{- $gatewayType := .Values.GATEWAY_SYSTEM_TYPE | default "" | toString -}}
{{- if $gatewayType -}}
{{- contains "legacy-ingress" $gatewayType -}}
{{- else -}}
{{- not (.Capabilities.APIVersions.Has "gateway.networking.k8s.io/v1") -}}
{{- end -}}
{{- else -}}
{{- .Values.ingress.enabled -}}
{{- end -}}
{{- end -}}

{{/*
Whether to render the Gateway API HTTPRoute resources. Uses .Values.gateway.enabled when
explicitly set (true/false); otherwise falls back to whether GATEWAY_SYSTEM_TYPE contains
"gateway-api-default", or, when GATEWAY_SYSTEM_TYPE is not set, to whether Gateway API CRDs
are available in the cluster.
*/}}
{{- define "spark-history-server.gatewayEnabled" -}}
{{- if eq .Values.gateway.enabled nil -}}
{{- $gatewayType := .Values.GATEWAY_SYSTEM_TYPE | default "" | toString -}}
{{- if $gatewayType -}}
{{- contains "gateway-api-default" $gatewayType -}}
{{- else -}}
{{- .Capabilities.APIVersions.Has "gateway.networking.k8s.io/v1" -}}
{{- end -}}
{{- else -}}
{{- .Values.gateway.enabled -}}
{{- end -}}
{{- end -}}

{{/*
Whether to render the OAuth2 Proxy legacy Ingress resource. Uses .Values.oauth2Proxy.ingress.enabled
when explicitly set (true/false); otherwise falls back to whether GATEWAY_SYSTEM_TYPE contains
"legacy-ingress", or, when GATEWAY_SYSTEM_TYPE is not set, to whether Gateway API CRDs are NOT
available in the cluster.
*/}}
{{- define "spark-history-server.oauth2Proxy.ingressEnabled" -}}
{{- if eq .Values.oauth2Proxy.ingress.enabled nil -}}
{{- $gatewayType := .Values.GATEWAY_SYSTEM_TYPE | default "" | toString -}}
{{- if $gatewayType -}}
{{- contains "legacy-ingress" $gatewayType -}}
{{- else -}}
{{- not (.Capabilities.APIVersions.Has "gateway.networking.k8s.io/v1") -}}
{{- end -}}
{{- else -}}
{{- .Values.oauth2Proxy.ingress.enabled -}}
{{- end -}}
{{- end -}}

{{/*
Whether to render the OAuth2 Proxy Gateway API HTTPRoute resources. Uses .Values.oauth2Proxy.gateway.enabled
when explicitly set (true/false); otherwise falls back to whether GATEWAY_SYSTEM_TYPE contains
"gateway-api-default", or, when GATEWAY_SYSTEM_TYPE is not set, to whether Gateway API CRDs are available
in the cluster.
*/}}
{{- define "spark-history-server.oauth2Proxy.gatewayEnabled" -}}
{{- if eq .Values.oauth2Proxy.gateway.enabled nil -}}
{{- $gatewayType := .Values.GATEWAY_SYSTEM_TYPE | default "" | toString -}}
{{- if $gatewayType -}}
{{- contains "gateway-api-default" $gatewayType -}}
{{- else -}}
{{- .Capabilities.APIVersions.Has "gateway.networking.k8s.io/v1" -}}
{{- end -}}
{{- else -}}
{{- .Values.oauth2Proxy.gateway.enabled -}}
{{- end -}}
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
{{- end }}

{{/*
All object labels
*/}}
{{- define "all_objects_labels_shs" -}}
{{ include "part_of_label_shs" . }}
{{ include "name_label_shs" . }}
{{- end }}

{{/*
Pod labels
*/}}
{{- define "pod_labels_shs" -}}
{{ include "part_of_label_shs" . }}
{{ include "name_label_shs" . }}
{{- end }}

{{/*
name label
*/}}
{{- define "name_label_shs" -}}
app.kubernetes.io/name: {{ template "spark-history-server.fullname" . }}
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

{{- define "historyServer.shouldOmitSecurityContext" -}}
{{- $omit := default true .Values.openShift.omit -}}
{{- if $omit -}}
  {{- .Capabilities.APIVersions.Has "security.openshift.io/v1" -}}
{{- else -}}
  false
{{- end -}}
{{- end -}}