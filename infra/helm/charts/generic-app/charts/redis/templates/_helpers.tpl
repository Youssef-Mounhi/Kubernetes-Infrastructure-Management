{{- define "redis.name" -}}
redis
{{- end }}

{{- define "redis.fullname" -}}
{{ .Release.Name }}-{{ include "redis.name" . }}
{{- end }}
