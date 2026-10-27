# ── Top-level prerequisites ──────────────────────────────────────────────────

variable "ibmcloud_api_key" {
  description = "IBM Cloud API key used to authenticate the provider."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "IBM Cloud region to deploy all resources into (e.g. 'us-south')."
  type        = string
  default     = "us-south"
}

variable "prefix" {
  description = "Short string prepended to every resource name for easy identification."
  type        = string
  default     = "ocp-platform"
}

variable "resource_group_name" {
  description = "Name of an existing IBM Cloud resource group, or a new one to create."
  type        = string
  default     = "ocp-platform-rg"
}

# ── VPC / Networking ──────────────────────────────────────────────────────────

variable "vpc_name" {
  description = "Base name for the VPC and all subnet/gateway resources."
  type        = string
  default     = "main"
}

variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC flow log collection."
  type        = bool
  default     = false
}

# ── OpenShift cluster ─────────────────────────────────────────────────────────

variable "cluster_name" {
  description = "Name assigned to the OpenShift / ROKS cluster."
  type        = string
  default     = "roks-cluster"
}

variable "ocp_version" {
  description = "OpenShift version to install (e.g. '4.16'). Null = IBM default."
  type        = string
  default     = null
}

variable "worker_machine_type" {
  description = "VPC worker node machine type (profile)."
  type        = string
  default     = "bx2.4x16"
}

variable "workers_per_zone" {
  description = "Number of worker nodes to place in each availability zone."
  type        = number
  default     = 1
}

variable "worker_os" {
  description = "Operating system for worker nodes."
  type        = string
  default     = "REDHAT_8_64"
}

variable "disable_public_endpoint" {
  description = "Set true to create a private-only cluster (no public Kube API endpoint)."
  type        = bool
  default     = false
}

# ── COS ───────────────────────────────────────────────────────────────────────

variable "cos_instance_name" {
  description = "Name of the Cloud Object Storage instance used for OCP registry storage."
  type        = string
  default     = "ocp-cos"
}

# ── Tags ──────────────────────────────────────────────────────────────────────

variable "resource_tags" {
  description = "User-defined tags attached to all created resources."
  type        = list(string)
  default     = []
}

variable "access_tags" {
  description = "IBM Cloud access management tags (IAM-level) for all resources."
  type        = list(string)
  default     = []
}
