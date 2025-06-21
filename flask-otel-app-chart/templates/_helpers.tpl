{{- define "flask-app.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "flask-app.fullname" -}}
{{- if eq .Release.Name .Chart.Name -}}
{{ .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Generate the environment variables for ConfigMap and Secret references
*/}}
{{- define "flask-app.envVars" -}}
  {{- range $key, $value := .Values.config }}
    - name: {{ $key }}
      valueFrom:
        configMapKeyRef:
          name: {{ .Release.Name }}-config
          key: {{ $key }}
  {{- end }}
{{- end }}
