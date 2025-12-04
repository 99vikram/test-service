{{/*
Expand the name of the chart.
*/}}
{{- define "api-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "api-service.fullname" -}}
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
{{- define "api-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "api-service.labels" -}}
helm.sh/chart: {{ include "api-service.chart" . }}
{{ include "api-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "api-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "api-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service labels
*/}}
{{- define "api-service.serviceLabels" -}}
app: {{ .serviceName }}
{{ include "api-service.labels" .root }}
{{- end }}

{{/*
Service selector labels
*/}}
{{- define "api-service.serviceSelectorLabels" -}}
app: {{ .serviceName }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "api-service.serviceAccountName" -}}
{{- if .serviceAccount.create }}
{{- default (printf "%s-%s" .root.Release.Name .serviceName) .serviceAccount.name }}
{{- else }}
{{- default "default" .serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get image repository
*/}}
{{- define "api-service.imageRepository" -}}
{{- if .image.repository }}
{{- if contains "/" .image.repository }}
{{- .image.repository }}
{{- else }}
{{- printf "%s/%s" .root.Values.global.imageRegistry .image.repository }}
{{- end }}
{{- else }}
{{- printf "%s/%s" .root.Values.global.imageRegistry .serviceName }}
{{- end }}
{{- end }}

{{/*
Get image tag
*/}}
{{- define "api-service.imageTag" -}}
{{- default .root.Values.global.imageTag .image.tag }}
{{- end }}

{{/*
Get full image
*/}}
{{- define "api-service.image" -}}
{{- printf "%s:%s" (include "api-service.imageRepository" .) (include "api-service.imageTag" .) }}
{{- end }}

{{/*
Security context for pod
*/}}
{{- define "api-service.podSecurityContext" -}}
{{- if .root.Values.global.securityContext }}
{{- toYaml .root.Values.global.securityContext }}
{{- end }}
{{- end }}

{{/*
Security context for container
*/}}
{{- define "api-service.containerSecurityContext" -}}
{{- if .root.Values.global.containerSecurityContext }}
{{- toYaml .root.Values.global.containerSecurityContext }}
{{- end }}
{{- end }}

{{/*
Create environment variables from service config
*/}}
{{- define "api-service.envVars" -}}
{{- range $key, $value := .env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- if and $.root.Values.configMap.enabled $.root.Values.configMap.data (ne (len $.root.Values.configMap.data) 0) (hasKey $.root.Values.configMap.data $.serviceName) }}
- name: CONFIG_MAP_NAME
  valueFrom:
    configMapKeyRef:
      name: {{ include "api-service.fullname" $.root }}-config
      key: {{ $.serviceName }}
{{- end }}
{{- if and $.root.Values.secret.enabled (or (and $.root.Values.secret.data (ne (len $.root.Values.secret.data) 0) (hasKey $.root.Values.secret.data $.serviceName)) (and $.root.Values.secret.stringData (ne (len $.root.Values.secret.stringData) 0) (hasKey $.root.Values.secret.stringData $.serviceName))) }}
- name: SECRET_NAME
  valueFrom:
    secretKeyRef:
      name: {{ include "api-service.fullname" $.root }}-secret
      key: {{ $.serviceName }}
{{- end }}
{{- end }}

{{/*
Create probe configuration
*/}}
{{- define "api-service.probe" -}}
{{- if .probe.grpc }}
{{- if .probe.initialDelaySeconds }}
initialDelaySeconds: {{ .probe.initialDelaySeconds }}
{{- end }}
{{- if .probe.periodSeconds }}
periodSeconds: {{ .probe.periodSeconds }}
{{- end }}
{{- if .probe.timeoutSeconds }}
timeoutSeconds: {{ .probe.timeoutSeconds }}
{{- end }}
{{- if .probe.successThreshold }}
successThreshold: {{ .probe.successThreshold }}
{{- end }}
{{- if .probe.failureThreshold }}
failureThreshold: {{ .probe.failureThreshold }}
{{- end }}
grpc:
  port: {{ .probe.grpc.port }}
{{- else if .probe.httpGet }}
{{- if .probe.initialDelaySeconds }}
initialDelaySeconds: {{ .probe.initialDelaySeconds }}
{{- end }}
{{- if .probe.periodSeconds }}
periodSeconds: {{ .probe.periodSeconds }}
{{- end }}
{{- if .probe.timeoutSeconds }}
timeoutSeconds: {{ .probe.timeoutSeconds }}
{{- end }}
{{- if .probe.successThreshold }}
successThreshold: {{ .probe.successThreshold }}
{{- end }}
{{- if .probe.failureThreshold }}
failureThreshold: {{ .probe.failureThreshold }}
{{- end }}
httpGet:
  path: {{ .probe.httpGet.path }}
  port: {{ .probe.httpGet.port }}
  {{- if .probe.httpGet.httpHeaders }}
  httpHeaders:
  {{- range .probe.httpGet.httpHeaders }}
  - name: {{ .name }}
    value: {{ .value }}
  {{- end }}
  {{- end }}
{{- else if .probe.tcpSocket }}
{{- if .probe.initialDelaySeconds }}
initialDelaySeconds: {{ .probe.initialDelaySeconds }}
{{- end }}
{{- if .probe.periodSeconds }}
periodSeconds: {{ .probe.periodSeconds }}
{{- end }}
{{- if .probe.timeoutSeconds }}
timeoutSeconds: {{ .probe.timeoutSeconds }}
{{- end }}
{{- if .probe.successThreshold }}
successThreshold: {{ .probe.successThreshold }}
{{- end }}
{{- if .probe.failureThreshold }}
failureThreshold: {{ .probe.failureThreshold }}
{{- end }}
tcpSocket:
  port: {{ .probe.tcpSocket.port }}
{{- end }}
{{- end }}

{{/*
Network Policy helper - check if service should have network policy
*/}}
{{- define "api-service.networkPolicyEnabled" -}}
{{- if and .root.Values.networkPolicy.enabled .service.enabled }}
{{- true }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

