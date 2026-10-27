provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

# Kubernetes provider — populated after cluster is provisioned.
provider "kubernetes" {
  host  = module.openshift.master_url
  token = data.ibm_container_cluster_config.ocp_config.token
  cluster_ca_certificate = base64decode(
    data.ibm_container_cluster_config.ocp_config.ca_certificate
  )
}
