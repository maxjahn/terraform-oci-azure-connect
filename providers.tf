variable "oci_tenancy_ocid" {}
variable "oci_user_ocid" {}
variable "oci_fingerprint" {}
variable "oci_private_key_path" {}
variable "oci_compartment_ocid" {}
variable "oci_region" {}

provider "oci" {
  version          = ">= 3.0.0"
  tenancy_ocid     = "${var.oci_tenancy_ocid}"
  user_ocid        = "${var.oci_user_ocid}"
  fingerprint      = "${var.oci_fingerprint}"
  private_key_path = "${var.oci_private_key_path}"
  region           = "${var.oci_region}"
}


variable "arm_subscription_id" {}
variable "arm_client_id" {}
variable "arm_client_secret" {}
variable "arm_tenant_id" {}

provider "azurerm" {
  version = ">=1.28.0"

  subscription_id = "${var.arm_subscription_id}"
  client_id       = "${var.arm_client_id}"
  client_secret   = "${var.arm_client_secret}"
  tenant_id       = "${var.arm_tenant_id}"

}



