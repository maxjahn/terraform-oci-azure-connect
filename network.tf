### azure #################################################
variable "arm_region" {}

# Create a resource group
resource "azurerm_resource_group" "oci_connect" {
  name     = "oci_connect"
  location = "${var.arm_region}"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "oci_connect_vnet" {
  name                = "oci-connect-network"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"
  location            = "${azurerm_resource_group.oci_connect.location}"
  address_space       = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "oci_connect_subnet" {
  name                 = "oci-connect-subnet"
  resource_group_name  = "${azurerm_resource_group.oci_connect.name}"
  virtual_network_name = "${azurerm_virtual_network.oci_connect_vnet.name}"
  address_prefix       = "10.0.2.64/28"
}

resource "azurerm_network_security_group" "oci_connect_sg" {
  name                = "OCIConnectSecurityGroup"
  location            = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"

  security_rule {
    name                       = "Ping"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${oci_core_subnet.az_connect_subnet.cidr_block}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OutboundAll"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    }
}


### oci ###################################################
resource "oci_core_virtual_network" "az_connect_vcn" {
  cidr_block     = "10.0.1.0/24"
  dns_label      = "azconnectvcn"
  compartment_id = "${var.oci_compartment_ocid}"
  display_name   = "az-connect-vcn"
}

resource "oci_core_subnet" "az_connect_subnet" {
    cidr_block = "10.0.1.32/28"
    compartment_id = "${var.oci_compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.az_connect_vcn.id}"
    display_name   = "az-connect-subnet"
}

resource "oci_core_drg" "az_connect_drg" {
    compartment_id = "${var.oci_compartment_ocid}"
    display_name   = "az-connect-drg"
}

resource "oci_core_drg_attachment" "az_conn_drg_attachment" {
    drg_id = "${oci_core_drg.az_connect_drg.id}"
    vcn_id = "${oci_core_virtual_network.az_connect_vcn.id}"
    display_name   = "az-connect-drg-attachment"
}

### security lists #########################################


resource "oci_core_security_list" "az_conn_security_list" {
    compartment_id = "${var.oci_compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.az_connect_vcn.id}"
    display_name = "az-conn-security-list"

    egress_security_rules {
        destination = "${azurerm_subnet.oci_connect_subnet.address_prefix}"
        protocol = "1" 
        icmp_options {
            type = "8"
            code = "8"
        }
    }
        
    egress_security_rules {
        destination = "${azurerm_subnet.oci_connect_subnet.address_prefix}"
        protocol = "6"
        tcp_options {
            min = "22"
            max = "22"
        }
    }   
    egress_security_rules {
        destination = "${azurerm_subnet.oci_connect_subnet.address_prefix}"
        protocol = "6"
        tcp_options {
            min = "8080"
            max = "8080"
        }
    }

    ingress_security_rules {
        source = "${azurerm_subnet.oci_connect_subnet.address_prefix}"
        protocol =  "1"
        icmp_options {
            type = "8"
            code = "8"
        }
    }


    ingress_security_rules {
        source = "${azurerm_subnet.oci_connect_subnet.address_prefix}"
        protocol =  "6"
        tcp_options {
            min = "22"
            max = "22"
        }
    }


    ingress_security_rules {
        source = "${azurerm_subnet.oci_connect_subnet.address_prefix}"
        protocol =  "6"
        tcp_options {
            min = "8080"
            max = "8080"
        }
    }


    ingress_security_rules {
        source = "${azurerm_subnet.oci_connect_subnet.address_prefix}"
        protocol =  "6"
        tcp_options {
            min = "1521"
            max = "1521"
        }
    }

}



