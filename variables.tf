variable "oci_tenancy_ocid" {}
variable "oci_user_ocid" {}
variable "oci_fingerprint" {}
variable "oci_private_key_path" {}
variable "oci_compartment_ocid" {}
variable "oci_region" {}

variable "arm_subscription_id" {}
variable "arm_client_id" {}
variable "arm_client_secret" {}
variable "arm_tenant_id" {}
variable "arm_region" {}

variable "ssh_public_key" {}

variable "oci_test_image" {
# oel 7.6
  default = "ocid1.image.oc1.iad.aaaaaaaaj6pcmnh6y3hdi3ibyxhhflvp3mj2qad4nspojrnxc6pzgn2w3k5q"
}

variable "oci_test_instances_count" {
  default = 1
}

variable "arm_test_instances_count" {
  default = 1
}

