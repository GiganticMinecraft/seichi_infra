# このファイルは Cloudflare provider v4 → v5 移行のためのステートクリーンアップ用です。
# v5 では旧リソースタイプが削除されているため、v4 の間にステートから除去する必要があります。
# apply 後、このファイルは削除してください。

# region cloudflare_access_application → cloudflare_zero_trust_access_application

removed {
  from = cloudflare_access_application.debug_admin_jmx
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.onp_admin_proxmox
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.onp_admin_proxmox_mon
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.onp_admin_zabbix
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.onp_admin_raritan
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.onp_hubble_ui
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.onp_phpmyadmin
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.onp_bugsink
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.onp_goldilocks
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_application.game_data_server
  lifecycle {
    destroy = false
  }
}

# endregion

# region cloudflare_access_policy (v5 では policies は access_application のインライン属性になる)

removed {
  from = cloudflare_access_policy.debug_admin_jmx
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.onp_admin_proxmox
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.onp_admin_proxmox_mon
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.onp_admin_zabbix
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.onp_admin_raritan
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.onp_hubble_ui
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.onp_phpmyadmin
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.onp_bugsink
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.onp_goldilocks
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_access_policy.game_data_server
  lifecycle {
    destroy = false
  }
}

# endregion

# region cloudflare_record → cloudflare_dns_record

removed {
  from = cloudflare_record.play
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_record.play_debug
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_record.github_pages
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_record.github_pages_command_reference
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_record.portal
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_record.playguide
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_record.local_tunnels
  lifecycle {
    destroy = false
  }
}

# endregion

# region cloudflare_access_identity_provider → cloudflare_zero_trust_access_identity_provider

removed {
  from = cloudflare_access_identity_provider.github_oauth
  lifecycle {
    destroy = false
  }
}

# endregion
