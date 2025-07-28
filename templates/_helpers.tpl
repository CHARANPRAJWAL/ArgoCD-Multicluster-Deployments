{{/*
Expand the name of the chart.
*/}}
{{- define "voting-app-argocd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "voting-app-argocd.fullname" -}}
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
{{- define "voting-app-argocd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "voting-app-argocd.labels" -}}
helm.sh/chart: {{ include "voting-app-argocd.chart" . }}
{{ include "voting-app-argocd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "voting-app-argocd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "voting-app-argocd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "voting-app-argocd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "voting-app-argocd.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Application template
*/}}
{{- define "application" -}}
{{- if .Values.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ .Values.name }}
  namespace: {{ .Values.argocd.namespace }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    environment: {{ .Values.environment }}
    component: {{ .Values.component }}
spec:
  project: {{ .Values.project }}
  source:
    repoURL: {{ .Values.source.repoURL }}
    targetRevision: {{ .Values.source.targetRevision }}
    path: {{ .Values.source.path }}
    {{- if .Values.source.helm }}
    helm:
      {{- toYaml .Values.source.helm | nindent 6 }}
    {{- end }}
  destination:
    server: {{ .Values.destination.server }}
    namespace: {{ .Values.destination.namespace }}
  syncPolicy:
    {{- toYaml .Values.syncPolicy | nindent 4 }}
{{- end }}
{{- end }} 