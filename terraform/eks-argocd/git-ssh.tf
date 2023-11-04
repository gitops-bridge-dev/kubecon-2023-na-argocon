locals {
  git_private_ssh_key = var.ssh_key_path # Update with the git ssh key to be used by ArgoCD
}
################################################################################
# GitOps Bridge: Private ssh keys for git
################################################################################
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [module.eks_blueprints_addons]
}
resource "kubernetes_secret" "git_secrets" {
  for_each = var.enable_git_ssh ? {
    git-addons = {
      type          = "git"
      url           = var.gitops_addons_org
      sshPrivateKey = file(pathexpand(local.git_private_ssh_key))
    }
    git-workloads = {
      type          = "git"
      url           = var.gitops_workload_org
      sshPrivateKey = file(pathexpand(local.git_private_ssh_key))
    }
  } : {}
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }
  data       = each.value
  depends_on = [kubernetes_namespace.argocd]
}
