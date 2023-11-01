############
## Akuity ##
############
variable "akp_org_name" {
  type        = string
  description = "Akuity Platform organization name."
}

variable "argocd_admin_password" {
  type        = string
  description = "The password to use for the `admin` Argo CD user."
}

variable "enable_git_ssh" {
  description = "use git ssh"
  type        = bool
  default     = false
}

variable "ssh_key_path" {
  description = "SSH key path for git access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

###########
##  GKE  ##
###########
variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes (per zone)"
}

variable "gke_project_id" {
  description = "project id"
}

variable "gke_region" {
  description = "region"
  default     = "us-west1"
}

############
## GitOps ##
############
variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    # aws
    enable_cert_manager     = true
    enable_external_secrets = true
    enable_kyverno          = true
    enable_ingress_nginx    = true
    # Use Akuity ArgoCD
    enable_argocd = false
  }
}
# Addons Git
variable "gitops_addons_org" {
  description = "Git repository org/user contains for addons"
  type        = string
  default     = "https://github.com/gitops-bridge-dev"
}
variable "gitops_addons_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "kubecon-2023-na-argocon"
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  type        = string
  default     = "main"
}
variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  type        = string
  default     = "gitops/"
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  type        = string
  default     = "bootstrap/control-plane/addons"
}
# Workloads Git
variable "gitops_workload_org" {
  description = "Git repository org/user contains for workload"
  type        = string
  default     = "https://github.com/gitops-bridge-dev"
}
variable "gitops_workload_repo" {
  description = "Git repository contains for workload"
  type        = string
  default     = "kubecon-2023-na-argocon"
}
variable "gitops_workload_revision" {
  description = "Git repository revision/branch/ref for workload"
  type        = string
  default     = "main"
}
variable "gitops_workload_basepath" {
  description = "Git repository base path for workload"
  type        = string
  default     = "gitops/"
}
variable "gitops_workload_path" {
  description = "Git repository path for workload"
  type        = string
  default     = "apps"
}

variable "enable_gitops_auto_bootstrap" {
  description = "Automatically deploy addons"
  type        = bool
  default     = true
}
