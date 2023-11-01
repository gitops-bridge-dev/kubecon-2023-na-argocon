# https://github.com/hashicorp/learn-terraform-provision-gke-cluster/blob/main/gke.tf

# GKE cluster
data "google_container_engine_versions" "gke_version" {
  location       = var.gke_region
  version_prefix = "1.27."
}

resource "google_container_cluster" "gke-01" {
  name     = local.name
  location = var.gke_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name     = google_container_cluster.gke-01.name
  location = var.gke_region
  cluster  = google_container_cluster.gke-01.name

  version    = data.google_container_engine_versions.gke_version.release_channel_latest_version["STABLE"]
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.gke_project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node", "${var.gke_project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Grant user `client` (as set by the `google_client_config` resources) cluster-admin.
# Used by the `akp_cluster` resource to install the Akuity Agent into the cluster.
data "google_client_config" "current" {}
resource "kubernetes_cluster_role_binding" "client_cluster_admin" {
  metadata {
    annotations = {}
    labels      = {}
    name        = "client-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "client"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [google_container_cluster.gke-01]
}