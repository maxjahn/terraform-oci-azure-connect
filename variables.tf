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
  default = "ocid1.image.oc1.iad.aaaaaaaa5qjfahpwztfurnuun23vlu7o5tiiijyjkrsfbtf4cgcdo4z5gena"
}
