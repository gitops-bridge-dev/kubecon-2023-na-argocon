provider "argocd" {
  server_addr = module.akuity.akuity_server_addr
  username    = "admin"
  password    = var.argocd_admin_password
}

resource "argocd_application" "bootstrap" {
  count = var.enable_gitops_auto_bootstrap ? 1 : 0

  metadata {
    name      = "bootstrap"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }
  cascade = false # disable cascading deletion
  wait    = true
  spec {
    project = "default"
    destination {
      name      = "in-cluster"
      namespace = "argocd"
    }
    source {
      repo_url        = local.gitops_addons_url
      path            = "${local.gitops_addons_basepath}${local.gitops_addons_path}"
      target_revision = local.gitops_addons_revision
      directory {
        recurse = true
        exclude = "exclude/*"
      }
    }
    source {
      repo_url        = local.gitops_workload_url
      path            = "${local.gitops_workload_basepath}bootstrap/workloads"
      target_revision = local.gitops_workload_revision
      directory {
        recurse = true
        exclude = "exclude/*"
      }
    }
    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }
    }
  }
  depends_on = [module.akuity]
}
