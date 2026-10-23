{{- range . }}
__result__	{{ .Class }}	{{ .Type }}
{{- range .Vulnerabilities }}
{{ .PkgName }}	{{ .InstalledVersion }}	{{ .Severity }}
{{- end }}{{ end }}
