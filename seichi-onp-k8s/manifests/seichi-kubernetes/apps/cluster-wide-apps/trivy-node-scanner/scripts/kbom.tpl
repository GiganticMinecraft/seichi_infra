{{- range . }}{{ $target := .Target }}{{ range .Vulnerabilities }}
{{ dict "event" "trivy_kbom_vulnerability" "target" $target "vuln_id" .VulnerabilityID "pkg_name" .PkgName "installed_version" .InstalledVersion "fixed_version" .FixedVersion "severity" .Severity "title" .Title | toJson }}
{{- end }}{{ end }}
