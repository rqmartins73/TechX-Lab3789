# ── Resource Group ────────────────────────────────────────────────────────────
output "resource_group_id" {
  description = "ID of the resource group that owns all platform resources."
  value       = module.resource_group.resource_group_id
}

# ── VPC ───────────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the provisioned VPC."
  value       = module.vpc.vpc_id
}

output "vpc_crn" {
  description = "CRN of the provisioned VPC."
  value       = module.vpc.vpc_crn
}

output "subnet_ids" {
  description = "All subnet IDs created in the VPC."
  value       = module.vpc.subnet_ids
}

output "subnet_detail_map" {
  description = "Full subnet detail map (id, CIDR, zone) for all subnets."
  value       = module.vpc.subnet_detail_map
}

output "public_gateways" {
  description = "Public gateways by zone."
  value       = module.vpc.public_gateways
}

# ── COS ───────────────────────────────────────────────────────────────────────
output "cos_instance_id" {
  description = "ID of the Cloud Object Storage instance."
  value       = module.cos.cos_instance_id
}

output "cos_instance_guid" {
  description = "GUID of the Cloud Object Storage instance."
  value       = module.cos.cos_instance_guid
}

# ── OpenShift Cluster ─────────────────────────────────────────────────────────
output "cluster_id" {
  description = "ID of the provisioned OpenShift cluster."
  value       = module.openshift.cluster_id
}

output "cluster_name" {
  description = "Name of the provisioned OpenShift cluster."
  value       = module.openshift.cluster_name
}

output "ocp_version" {
  description = "OpenShift version running on the cluster."
  value       = module.openshift.ocp_version
}

output "master_url" {
  description = "Kubernetes API server URL."
  value       = module.openshift.master_url
}

output "private_service_endpoint_url" {
  description = "Private service endpoint URL for the cluster."
  value       = module.openshift.private_service_endpoint_url
}

output "public_service_endpoint_url" {
  description = "Public service endpoint URL (empty when public endpoint disabled)."
  value       = module.openshift.public_service_endpoint_url
}

output "ingress_hostname" {
  description = "Ingress subdomain hostname assigned to the cluster."
  value       = module.openshift.ingress_hostname
}

output "cluster_crn" {
  description = "CRN of the OpenShift cluster."
  value       = module.openshift.cluster_crn
}
