removed {
  from = kubernetes_namespace.onp_seichi_debug_gateway

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_seichi_debug_gateway
  id = "seichi-debug-gateway"
}
removed {
  from = kubernetes_namespace.onp_seichi_debug_minecraft

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_seichi_debug_minecraft
  id = "seichi-debug-minecraft"
}
removed {
  from = kubernetes_namespace.onp_seichi_gateway

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_seichi_gateway
  id = "seichi-gateway"
}
removed {
  from = kubernetes_namespace.onp_seichi_minecraft

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_seichi_minecraft
  id = "seichi-minecraft"
}
removed {
  from = kubernetes_namespace.onp_argocd

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_argocd
  id = "argocd"
}
removed {
  from = kubernetes_namespace.onp_argo

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_argo
  id = "argo"
}
removed {
  from = kubernetes_namespace.onp_monitoring

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_monitoring
  id = "monitoring"
}
removed {
  from = kubernetes_namespace.onp_synology_csi

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_synology_csi
  id = "synology-csi"
}
removed {
  from = kubernetes_namespace.onp_democratic_csi

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.onp_democratic_csi
  id = "democratic-csi"
}
removed {
  from = kubernetes_namespace.cloudflared_tunnel_exits

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.cloudflared_tunnel_exits
  id = "cloudflared-tunnel-exits"
}
removed {
  from = kubernetes_namespace.garage

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.garage
  id = "garage"
}
removed {
  from = kubernetes_namespace.garage_admin

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.garage_admin
  id = "garage-admin"
}
removed {
  from = kubernetes_namespace.kyverno

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.kyverno
  id = "kyverno"
}
removed {
  from = kubernetes_namespace.kubechecks

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_namespace_v1.kubechecks
  id = "kubechecks"
}
removed {
  from = kubernetes_secret.onp_argocd_github_oauth_app_secret

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_argocd_github_oauth_app_secret
  id = "argocd/argocd-github-oauth-app-secret"
}
removed {
  from = kubernetes_secret.onp_argocd_applicationset_controller_github_app_secret

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_argocd_applicationset_controller_github_app_secret
  id = "argocd/argocd-applicationset-controller-github-app-secret"
}
removed {
  from = kubernetes_secret.onp_argocd_workflows_sso

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_argocd_workflows_sso
  id = "argocd/argo-workflows-sso"
}
removed {
  from = kubernetes_secret.onp_argo_workflows_sso

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_argo_workflows_sso
  id = "argo/argo-workflows-sso"
}
removed {
  from = kubernetes_secret.onp_grafana_github_oauth_app_secret

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_grafana_github_oauth_app_secret
  id = "monitoring/grafana-github-oauth-app-secret"
}
removed {
  from = kubernetes_secret.onp_synology_csi

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_synology_csi
  id = "synology-csi/client-info-secret"
}
removed {
  from = kubernetes_secret.onp_democratic_csi_sc_truenas_03

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_democratic_csi_sc_truenas_03
  id = "democratic-csi/democratic-csi-driver-config-sc-truenas-03"
}
removed {
  from = kubernetes_secret.cloudflared_tunnel_credential

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.cloudflared_tunnel_credential
  id = "cloudflared-tunnel-exits/cloudflared-tunnel-credential"
}
removed {
  from = kubernetes_secret.garage_loki_credentials

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_loki_credentials
  id = "monitoring/garage-loki-credentials"
}
removed {
  from = kubernetes_secret.garage_thanos_credentials

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_thanos_credentials
  id = "monitoring/garage-thanos-credentials"
}
removed {
  from = kubernetes_secret.garage_seichi_minecraft_credentials

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_seichi_minecraft_credentials
  id = "seichi-minecraft/garage-s3-credentials"
}
removed {
  from = kubernetes_secret.garage_backup_s3_credentials

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_backup_s3_credentials
  id = "garage/garage-backup-s3-credentials"
}
removed {
  from = kubernetes_secret.garage_backup_failure_notify_webhook

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_backup_failure_notify_webhook
  id = "garage/backup-failure-notify-webhook"
}
removed {
  from = kubernetes_secret.garage_admin_api_token

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_admin_api_token
  id = "garage/garage-admin-api-token"
}
removed {
  from = kubernetes_secret.garage_admin_github_oauth

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_admin_github_oauth
  id = "garage-admin/garage-admin-github-oauth"
}
removed {
  from = kubernetes_secret.garage_admin_token

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_admin_token
  id = "garage-admin/garage-admin-token"
}
removed {
  from = kubernetes_secret.garage_admin_s3

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.garage_admin_s3
  id = "garage-admin/garage-admin-s3"
}
removed {
  from = kubernetes_secret.truenas_exporter_api_key

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.truenas_exporter_api_key
  id = "monitoring/truenas-exporter-api-key"
}
removed {
  from = kubernetes_secret.onp_kubechecks_github_app_secret

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_kubechecks_github_app_secret
  id = "kubechecks/kubechecks-github-app-secret"
}
removed {
  from = kubernetes_secret.mariadb_monitoring_password

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.mariadb_monitoring_password
  id = "seichi-minecraft/mariadb-monitoring-password"
}
removed {
  from = kubernetes_secret.mariadb_pr_review_password

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.mariadb_pr_review_password
  id = "kube-system/mariadb-pr-review-password"
}
removed {
  from = kubernetes_secret.idea_reaction_discord_token

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.idea_reaction_discord_token
  id = "seichi-minecraft/idea-reaction-discord-token"
}
removed {
  from = kubernetes_secret.idea_reaction_redmine_api_key

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.idea_reaction_redmine_api_key
  id = "seichi-minecraft/idea-reaction-redmine-api-key"
}
removed {
  from = kubernetes_secret.babyrite_discord_token

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.babyrite_discord_token
  id = "seichi-minecraft/babyrite-discord-token"
}
removed {
  from = kubernetes_secret.onp_minecraft_debug_secrets

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_debug_secrets
  id = "seichi-debug-minecraft/mcserver--common--config-secrets"
}
removed {
  from = kubernetes_secret.onp_minecraft_debug_seichiassist_webhook_secrets

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_debug_seichiassist_webhook_secrets
  id = "seichi-debug-minecraft/mcserver--seichiassist-webhook--config-secrets"
}
removed {
  from = kubernetes_secret.onp_minecraft_prod_secrets

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_prod_secrets
  id = "seichi-minecraft/mcserver--common--config-secrets"
}
removed {
  from = kubernetes_secret.onp_minecraft_prod_lobby_secrets

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_prod_lobby_secrets
  id = "seichi-minecraft/mcserver--lobby--config-secrets"
}
removed {
  from = kubernetes_secret.onp_minecraft_prod_seichiassist_webhook_secrets

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_prod_seichiassist_webhook_secrets
  id = "seichi-minecraft/mcserver--seichiassist-webhook--config-secrets"
}
removed {
  from = kubernetes_secret.onp_minecraft_prod_one_day_to_reset_secrets

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_prod_one_day_to_reset_secrets
  id = "seichi-minecraft/mcserver--one-day-to-reset--config-secrets"
}
removed {
  from = kubernetes_secret.onp_minecraft_prod_kagawa_secrets

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_prod_kagawa_secrets
  id = "seichi-minecraft/mcserver--kagawa--config-secrets"
}
removed {
  from = kubernetes_secret.argo_events_github_access_token

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.argo_events_github_access_token
  id = "seichi-minecraft/argo-events-github-access-token"
}
removed {
  from = kubernetes_secret.seichiassist_downloader_develop_release_notify_webhook

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.seichiassist_downloader_develop_release_notify_webhook
  id = "seichi-minecraft/seichiassist-downloader-develop-release-notify-webhook"
}
removed {
  from = kubernetes_secret.seichiassist_downloader_master_release_notify_webhook

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.seichiassist_downloader_master_release_notify_webhook
  id = "seichi-minecraft/seichiassist-downloader-master-release-notify-webhook"
}
removed {
  from = kubernetes_secret.onp_minecraft_prod_bugsink_admin_password

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_prod_bugsink_admin_password
  id = "seichi-minecraft/bugsink-admin-password"
}
removed {
  from = kubernetes_secret.onp_minecraft_prod_mariadb_root_password

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_prod_mariadb_root_password
  id = "seichi-minecraft/mariadb"
}
removed {
  from = kubernetes_secret.onp_minecraft_debug_mariadb_root_password

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.onp_minecraft_debug_mariadb_root_password
  id = "seichi-debug-minecraft/mariadb"
}
removed {
  from = kubernetes_secret.seichi_portal_meilisearch_master_key

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.seichi_portal_meilisearch_master_key
  id = "seichi-minecraft/seichi-portal-meilisearch-master-key"
}
removed {
  from = kubernetes_secret.tailscale_approval_bot_secrets

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.tailscale_approval_bot_secrets
  id = "seichi-minecraft/tailscale-approval-bot-secrets"
}
removed {
  from = kubernetes_secret.backup_failure_notify_webhook

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.backup_failure_notify_webhook
  id = "seichi-minecraft/backup-failure-notify-webhook"
}
removed {
  from = kubernetes_secret.argocd_backup_workflow_auth_token

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.argocd_backup_workflow_auth_token
  id = "seichi-minecraft/argocd-auth-token"
}
removed {
  from = kubernetes_secret.pbs_credentials

  lifecycle {
    destroy = false
  }
}

import {
  to = kubernetes_secret_v1.pbs_credentials
  id = "seichi-minecraft/pbs-credentials"
}
