variable "oci_tenancy_ocid" {}
variable "oci_user_ocid" {}
variable "oci_fingerprint" {}
variable "oci_private_key_path" {}
variable "oci_compartment_ocid" {}
variable "oci_region" {}

variable "oci_cidr_vcn" {}
variable "oci_cidr_subnet" {}

variable "arm_subscription_id" {}
variable "arm_client_id" {}
variable "arm_client_secret" {}
variable "arm_tenant_id" {}
variable "arm_region" {}

variable "arm_cidr_vnet" {}
variable "arm_cidr_subnet" {}
variable "arm_cidr_gw_subnet" {}

variable "ssh_public_key" {}

variable "peering_net" {}

variable "oci_test_image" {}

variable "oci_test_instances_count" {
  default = 2
}

variable "arm_test_instances_count" {
  default = 2
}

