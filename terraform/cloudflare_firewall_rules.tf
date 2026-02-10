import {
  to = cloudflare_ruleset.custom_firewall_rules
  id = "zone/77c10fdfa7c65de4d14903ed8879ebcb/59aa12fc3a7d403db8419a634c223d41"
}

resource "cloudflare_ruleset" "custom_firewall_rules" {
  zone_id     = local.cloudflare_zone_id
  name        = "default"
  description = ""
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = "skip"
    expression  = "(http.host eq \"grafana.onp-k8s.admin.seichi.click\")"
    description = "Allow Grafana Dashboard Queries"
    action_parameters {
      phases = ["http_request_firewall_managed"]
    }
    logging {
      enabled = true
    }
    enabled = true
  }

  rules {
    action      = "skip"
    expression  = "(http.host eq \"s1-map-gigantic.seichi.click\" and http.request.uri.path eq \"/resourcepacks/seichi_tex_latest.zip\")"
    description = "リソースパック"
    action_parameters {
      products = ["bic"]
    }
    logging {
      enabled = true
    }
    enabled = true
  }

  rules {
    action      = "skip"
    expression  = "(ip.geoip.asnum eq 15169 and http.host eq \"redmine.seichi.click\" and http.request.uri.path eq \"/issues.xml\")"
    description = "Permit Google App Script to Redmine"
    action_parameters {
      products = ["waf"]
    }
    logging {
      enabled = true
    }
    enabled = true
  }

  rules {
    action      = "skip"
    expression  = "(http.request.uri.path eq \"/api/dashboards/import\") or (http.request.uri.path eq \"/api/dashboards/db\")"
    description = "bypass-waf-grafana-add-dashboards"
    action_parameters {
      products = ["waf"]
    }
    logging {
      enabled = true
    }
    enabled = true
  }

  rules {
    action      = "skip"
    expression  = "http.host eq \"minio-console.onp-k8s.admin.seichi.click\""
    description = "Let MinIO API requests bypass WAF rules"
    action_parameters {
      products = ["waf"]
    }
    logging {
      enabled = true
    }
    enabled = true
  }

  rules {
    action      = "skip"
    expression  = "http.host eq \"phpmyadmin.onp-k8s.admin.seichi.click\""
    description = "Let phpMyAdmin requests bypass WAF rules"
    action_parameters {
      products = ["waf"]
    }
    logging {
      enabled = true
    }
    enabled = true
  }
}
