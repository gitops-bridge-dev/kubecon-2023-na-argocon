################################################################################
# EKS Blueprints Addons
################################################################################
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Using GitOps Bridge (Skip Helm Install in Terraform)
  create_kubernetes_resources = false

  # EKS Blueprints Addons
  enable_cert_manager                 = var.addons.enable_cert_manager
  enable_aws_efs_csi_driver           = var.addons.enable_aws_efs_csi_driver
  enable_aws_fsx_csi_driver           = var.addons.enable_aws_fsx_csi_driver
  enable_aws_cloudwatch_metrics       = var.addons.enable_aws_cloudwatch_metrics
  enable_aws_privateca_issuer         = var.addons.enable_aws_privateca_issuer
  enable_cluster_autoscaler           = var.addons.enable_cluster_autoscaler
  enable_external_dns                 = var.addons.enable_external_dns
  enable_external_secrets             = var.addons.enable_external_secrets
  enable_aws_load_balancer_controller = var.addons.enable_aws_load_balancer_controller
  enable_fargate_fluentbit            = var.addons.enable_fargate_fluentbit
  enable_aws_for_fluentbit            = var.addons.enable_aws_for_fluentbit
  enable_aws_node_termination_handler = var.addons.enable_aws_node_termination_handler
  enable_karpenter                    = var.addons.enable_karpenter
  enable_velero                       = var.addons.enable_velero
  enable_aws_gateway_api_controller   = var.addons.enable_aws_gateway_api_controller

  tags = local.tags

  depends_on = [module.eks]
}

locals {

  cluster_metadata = merge(
    module.eks_blueprints_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = local.region
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = module.vpc.vpc_id
    },
    {
      addons_repo_url      = "${var.gitops_addons_org}/${var.gitops_addons_repo}"
      addons_repo_basepath = var.gitops_addons_basepath
      addons_repo_path     = var.gitops_addons_path
      addons_repo_revision = var.gitops_addons_revision
    },
    {
      workload_repo_url      = "${var.gitops_workload_org}/${var.gitops_workload_repo}"
      workload_repo_basepath = var.gitops_workload_basepath
      workload_repo_path     = var.gitops_workload_path
      workload_repo_revision = var.gitops_workload_revision
    }
  )

  cluster_labels = merge(
    var.addons,
    { environment = "dev" },
    { kubernetes_version = var.kubernetes_version },
    { aws_cluster_name = module.eks.cluster_name }
  )

}

################################################################################
# GitOps Bridge: Bootstrap for In-Cluster
################################################################################
module "gitops_bridge_bootstrap" {
  source = "github.com/gitops-bridge-dev/gitops-bridge-argocd-bootstrap-terraform?ref=v2.0.0"

  cluster = {
    metadata = local.cluster_metadata
    addons   = local.cluster_labels
  }
  #apps       = local.argocd_apps
  argocd = {
    create_namespace = false
    set = [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      }
    ]
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt_hash.argo.id
      }
    ]
  }
  depends_on = [module.eks_blueprints_addons, kubernetes_namespace.argocd, kubernetes_secret.git_secrets]
}

################################################################################
# GitOps Bridge: Bootstrap for Apps
################################################################################
module "argocd" {
  source = "./modules/argocd-bootstrap"

  count = var.enable_gitops_auto_bootstrap ? 1 : 0

  addons = {
    repo_url        = "${var.gitops_addons_org}/${var.gitops_addons_repo}"
    path            = "${var.gitops_addons_basepath}${var.gitops_addons_path}"
    target_revision = var.gitops_addons_revision
  }
  workloads = {
    repo_url        = "${var.gitops_workload_org}/${var.gitops_workload_repo}"
    path            = "${var.gitops_workload_basepath}bootstrap/workloads"
    target_revision = var.gitops_addons_revision
  }
  depends_on = [module.gitops_bridge_bootstrap]
}
