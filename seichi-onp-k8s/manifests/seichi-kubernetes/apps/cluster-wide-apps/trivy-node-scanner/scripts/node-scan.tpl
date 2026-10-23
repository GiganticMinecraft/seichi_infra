{{- range . }}{{ range .Vulnerabilities }}
{{ .PkgName }}	{{ .InstalledVersion }}	{{ .Severity }}
{{- end }}{{ end }}
