
resource "akp_instance" "argocd" {
  name = "gitops-bridge"
  argocd = {
    "spec" = {
      "instance_spec" = {
        "declarative_management_enabled" = true
      }
      "version" = "v2.8.4"
    }
  }
  argocd_cm = {
    # When configuring the `argocd_cm`, make sure to specify the following keys
    # (from "admin.enabled", to "users.anonymous.enabled") since those keys are
    # added by Akuity Platform by default. If they are not defined, you may see
    # inconsistent results and errors from the provider. Feel free to customize
    # the values based on your usage, but the keys themselves must be specified.
    # Note that "admin.enabled" cannot be set to true independently, and an
    # "accounts.admin" key is required, like the "accounts.alice" key below, once
    # you add that, remove the "admin.enabled" key.
    # "admin.enabled"                  = true
    "exec.enabled"                   = false
    "ga.anonymizeusers"              = false
    "helm.enabled"                   = true
    "kustomize.enabled"              = true
    "server.rbac.log.enforce.enable" = false
    "statusbadge.enabled"            = false
    "ui.bannerpermanent"             = false
    "users.anonymous.enabled"        = false

    "accounts.admin" = "login"
  }
  argocd_secret = {
    "admin.password" = bcrypt(var.argocd_admin_password)
  }
  repo_credential_secrets = var.repo_credential_secrets
  lifecycle {
    ignore_changes = [
      argocd_secret["admin.password"],
    ]
  }
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster.cluster_name
}
data "aws_eks_cluster" "this" {
  name = var.cluster.cluster_name
}
locals {
  environment = try(var.cluster.environment, "dev")
}
resource "akp_cluster" "gitops_bridge" {
  instance_id = akp_instance.argocd.id
  kube_config = {
    host                   = data.aws_eks_cluster.this.endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  }
  name        = "${var.cluster.cluster_name}-${local.environment}"
  namespace   = "akuity"
  labels      = merge({ environment = local.environment }, var.cluster.addons)
  annotations = var.cluster.metadata
  spec = {
    description = "${var.cluster.cluster_name}-${local.environment} cluster"
    data = {
      size = "small"
    }
  }
  remove_agent_resources_on_destroy = false

  # When using a Kubernetes token retrieved from a Terraform provider
  # (e.g. aws_eks_cluster_auth or google_client_config) in the above `kube_config`,
  # the token value may change over time. This will cause Terraform to detect a diff
  # in the `token` on each plan and apply. To prevent constant changes, you can add
  # the `token` field path to the `lifecycle` block's `ignore_changes` list:
  # https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#ignore_changes
  lifecycle {
    ignore_changes = [
      kube_config.token,
    ]
  }
}
