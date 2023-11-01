resource "argocd_application" "bootstrap_addons" {

  metadata {
    name      = "bootstrap-addons"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }
  cascade = true
  wait    = true
  spec {
    project = "default"
    destination {
      name      = "in-cluster"
      namespace = "argocd"
    }
    source {
      repo_url        = var.addons.repo_url
      path            = var.addons.path
      target_revision = var.addons.target_revision
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
}

resource "argocd_application" "bootstrap_workloads" {

  metadata {
    name      = "bootstrap-workloads"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }
  cascade = true
  wait    = true
  spec {
    project = "default"
    destination {
      name      = "in-cluster"
      namespace = "argocd"
    }
    source {
      repo_url        = var.workloads.repo_url
      path            = var.workloads.path
      target_revision = var.workloads.target_revision
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
  depends_on = [ argocd_application.bootstrap_addons ]
}


