# VPC
resource "google_compute_network" "vpc" {
  name = "${var.gke_project_id}-gitops-bridge-demo-vpc"
  # name                    = "${var.gke_project_id}-${local.cluster_name}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.gke_project_id}-${local.name}-subnet"
  region        = var.gke_region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

# External IP
resource "google_compute_address" "static" {
  name = "${local.name}-static"
}