# =============================================================================
#  VPC + OpenShift Container Platform
#  Modules: resource-group → cos → landing-zone-vpc → base-ocp-vpc
# =============================================================================

# ── 1. Resource Group ─────────────────────────────────────────────────────────
module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"

  resource_group_name             = var.resource_group_name
  existing_resource_group_name    = var.resource_group_name
}

# ── 2. Cloud Object Storage (OCP internal image registry) ────────────────────
module "cos" {
  source  = "terraform-ibm-modules/cos/ibm"
  version = "11.1.5"

  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  cos_instance_name = "${var.prefix}-${var.cos_instance_name}"
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags
}

# ── 3. Multi-Zone VPC (3 AZs, 2 subnet tiers per zone: workers + LB) ─────────
#
#  Subnet layout (10.x.0.0/16 address space per zone):
#    zone-1  10.10.10.0/24  worker nodes   | 10.10.20.0/24  load balancers
#    zone-2  10.20.10.0/24  worker nodes   | 10.20.20.0/24  load balancers
#    zone-3  10.30.10.0/24  worker nodes   | 10.30.20.0/24  load balancers
#
module "vpc" {
  source  = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version = "10.1.5"

  name              = var.vpc_name
  region            = var.region
  resource_group_id = module.resource_group.resource_group_id
  prefix            = var.prefix
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags

  # Public gateways allow worker nodes to reach the internet (pull images, etc.)
  use_public_gateways = {
    zone-1 = true
    zone-2 = true
    zone-3 = true
  }

  subnets = {
    zone-1 = [
      {
        name           = "worker-zone-1"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      },
      {
        name           = "lb-zone-1"
        cidr           = "10.10.20.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ]
    zone-2 = [
      {
        name           = "worker-zone-2"
        cidr           = "10.20.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      },
      {
        name           = "lb-zone-2"
        cidr           = "10.20.20.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ]
    zone-3 = [
      {
        name           = "worker-zone-3"
        cidr           = "10.30.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      },
      {
        name           = "lb-zone-3"
        cidr           = "10.30.20.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ]
  }

  # Egress/ingress rules applied at the ACL level for all subnets
  network_acls = [
    {
      name                         = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules                        = []
    }
  ]

  # Default security-group rules – allow HTTPS inbound + all outbound
  security_group_rules = [
    {
      name      = "allow-https-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      protocol  = "tcp"
      port_min  = 443
      port_max  = 443
    },
    {
      name      = "allow-all-outbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
    }
  ]

  # Flow logs — requires COS bucket name when enabled
  enable_vpc_flow_logs            = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = var.enable_vpc_flow_logs
  existing_cos_instance_guid      = var.enable_vpc_flow_logs ? module.cos.cos_instance_guid : null
}

# ── 4. Local – extract only the *worker* subnets for the OCP cluster ──────────
#
# The VPC module's subnet_detail_map contains ALL subnets (worker + lb).
# base-ocp-vpc expects only the subnets the cluster workers will use.
# We build a filtered map keyed by subnet_prefix that matches the module's
# expected  map(list(object({id, zone, cidr_block})))  shape.
#
locals {
  worker_subnets = {
    for key, subnet_list in module.vpc.subnet_detail_map :
    key => [
      for s in subnet_list :
      {
        id         = s.id
        zone       = s.zone
        cidr_block = s.cidr
      }
      if can(regex("worker", s.name))
    ]
    if length([for s in subnet_list : s if can(regex("worker", s.name))]) > 0
  }
}

# ── 5. OpenShift / ROKS Cluster ───────────────────────────────────────────────
module "openshift" {
  source  = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version = "4.1.0"

  cluster_name      = "${var.prefix}-${var.cluster_name}"
  region            = var.region
  vpc_id            = module.vpc.vpc_id
  vpc_subnets       = local.worker_subnets
  resource_group_id = module.resource_group.resource_group_id
  ocp_version       = var.ocp_version
  resource_tags     = var.resource_tags
  access_tags       = var.access_tags

  # Re-use the shared COS instance for the OCP internal image registry
  use_existing_cos       = true
  existing_cos_id        = module.cos.cos_instance_id
  enable_registry_storage = true

  disable_public_endpoint = var.disable_public_endpoint

  # One default worker pool spanning all three zones
  worker_pools = [
    {
      pool_name        = "default"
      machine_type     = var.worker_machine_type
      workers_per_zone = var.workers_per_zone
      operating_system = var.worker_os
      # subnet_prefix references the key used in vpc_subnets above
      subnet_prefix    = null
    }
  ]

  # Wait until Ingress is healthy before Terraform completes
  cluster_ready_when = "IngressReady"
}

# ── 6. Cluster config data source (feeds the kubernetes provider) ─────────────
data "ibm_container_cluster_config" "ocp_config" {
  cluster_name_id   = module.openshift.cluster_id
  resource_group_id = module.resource_group.resource_group_id
  config_dir        = "/tmp"
}
