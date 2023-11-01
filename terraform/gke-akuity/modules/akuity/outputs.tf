output "akuity_server_addr" {
  value = "${akp_instance.argocd.argocd.spec.instance_spec.subdomain}.cd.akuity.cloud:443"
}