locals {
  name   = "ex-${replace(basename(path.cwd), "_", "-")}"
  region = var.gke_region

  # cluster_version = var.kubernetes_version

  # vpc_cidr = var.vpc_cidr
  git_private_ssh_key = var.ssh_key_path # Update with the git ssh key to be used by ArgoCD

  gitops_addons_org      = var.gitops_addons_org
  gitops_addons_repo     = var.gitops_addons_repo
  gitops_addons_url      = "${local.gitops_addons_org}/${local.gitops_addons_repo}"
  gitops_addons_basepath = var.gitops_addons_basepath
  gitops_addons_path     = var.gitops_addons_path
  gitops_addons_revision = var.gitops_addons_revision

  gitops_workload_org      = var.gitops_workload_org
  gitops_workload_repo     = var.gitops_workload_repo
  gitops_workload_basepath = var.gitops_workload_basepath
  gitops_workload_path     = var.gitops_workload_path
  gitops_workload_revision = var.gitops_workload_revision
  gitops_workload_url      = "${local.gitops_workload_org}/${local.gitops_workload_repo}"

  oss_addons = {
    enable_argocd         = try(var.addons.enable_argocd, true)
    enable_argo_rollouts  = try(var.addons.enable_argo_rollouts, false)
    enable_argo_events    = try(var.addons.enable_argo_events, false)
    enable_argo_workflows = try(var.addons.enable_argo_workflows, false)
    enable_ingress_nginx  = try(var.addons.enable_ingress_nginx, false)
  }
  addons = merge(
    local.oss_addons,
    # { kubernetes_version = local.cluster_version },
    { cluster_name = local.name }
  )

  addons_metadata = merge(
    {
      addons_repo_url      = local.gitops_addons_url
      addons_repo_basepath = local.gitops_addons_basepath
      addons_repo_path     = local.gitops_addons_path
      addons_repo_revision = local.gitops_addons_revision
    },
    {
      workload_repo_url      = local.gitops_workload_url
      workload_repo_basepath = local.gitops_workload_basepath
      workload_repo_path     = local.gitops_workload_path
      workload_repo_revision = local.gitops_workload_revision
    }
  )

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/gitops-bridge-dev/gitops-bridge"
  }
}

################################################################################
# GitOps Bridge: Bootstrap for Akuity
################################################################################
module "akuity" {
  source = "./modules/akuity"

  argocd_admin_password = var.argocd_admin_password

  cluster = {
    cluster_name = local.name
    metadata     = local.addons_metadata
    addons       = local.addons
  }
  gke_region = var.gke_region
  repo_credential_secrets = var.enable_git_ssh ? {
    repo-my-private-ssh-repo = {
      url           = local.gitops_addons_url
      sshPrivateKey = file(pathexpand(local.git_private_ssh_key))
    }
  } : {}
  depends_on = [google_container_cluster.gke-01]
}

################################################################################
# GitOps Bridge: Bootstrap for Apps
################################################################################
module "argocd" {
  source = "./modules/argocd-bootstrap"

  addons = {
    repo_url        = local.gitops_addons_url
    path            = "${local.gitops_addons_basepath}${local.gitops_addons_path}"
    target_revision = local.gitops_addons_revision
  }
  workloads = {
    repo_url        = local.gitops_workload_url
    path            = "${local.gitops_workload_basepath}bootstrap/workloads"
    target_revision = local.gitops_addons_revision
  }
  depends_on = [module.akuity]
}
