{{- define "aqua-os.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "aqua-os.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: aqua-os
{{- end }}

{{- define "aqua-os.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
