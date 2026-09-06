{{/* Helper template for labels and names */}}
{{- define "bankapp.name" -}}
{{ .Values.app.name | default "bankapp" }}
{{- end -}}

{{- define "bankapp.fullname" -}}
{{ printf "%s-%s" (include "bankapp.name" .) .Release.Name }}
{{- end -}}

{{- define "bankapp.labels" -}}
app.kubernetes.io/name: {{ include "bankapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: Helm
{{- end -}}
