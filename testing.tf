### oci testing 

resource "oci_core_internet_gateway" "oci_test_igw" {
  display_name   = "oci-test-internet-gateway"
  compartment_id = "${var.oci_compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.az_connect_vcn.id}"
}

data "oci_identity_availability_domains" "az_connect_adcomp" {
  compartment_id = "${var.oci_compartment_ocid}"
}

resource "oci_core_instance" "az_connect_test_instance" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.az_connect_adcomp.availability_domains[0],"name")}"
  compartment_id      = "${var.oci_compartment_ocid}"
  shape               = "VM.Standard2.1"

  create_vnic_details {
    subnet_id              = "${oci_core_subnet.az_connect_subnet.id}"
    skip_source_dest_check = true
  }

  display_name = "az-connect-test-instance"

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }

  source_details {
    source_id   = "${var.oci_test_image}"
    source_type = "image"
  }

  preserve_boot_volume = false
}

output "oci_vm_private_ip" {
  value = "${oci_core_instance.az_connect_test_instance.private_ip}"
}

output "oci_vm_public_ip" {
  value = "${oci_core_instance.az_connect_test_instance.public_ip}"
}

### azure testing

resource "azurerm_public_ip" "oci_test_ip" {
  name                = "oci-test-ip"
  location            = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "oci_testvm_nic" {
  name                = "oci-testvm-nic"
  location            = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"

  ip_configuration {
    name                          = "oci-testvm-nic-config"
    subnet_id                     = "${azurerm_subnet.oci_connect_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.oci_test_ip.id}"
  }
}

resource "azurerm_virtual_machine" "oci_testvm" {
  name                  = "oci-testvm"
  location              = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name   = "${azurerm_resource_group.oci_connect.name}"
  network_interface_ids = ["${azurerm_network_interface.oci_testvm_nic.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "oci-test"
    admin_username = "az"
    admin_password = "Welcome-1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      key_data = "${var.ssh_public_key}"
      path     = "/home/az/.ssh/authorized_keys"
    }
  }
}

output "azure_vm_private_ip" {
  value = "${azurerm_network_interface.oci_testvm_nic.private_ip_address}"
}

output "azure_vm_public_ip" {
  value = "${azurerm_public_ip.oci_test_ip.ip_address}"
}
