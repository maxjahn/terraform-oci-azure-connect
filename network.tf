### azure #################################################

resource "azurerm_resource_group" "oci_connect" {
  name     = "oci_connect"
  location = "${var.arm_region}"
}

resource "azurerm_virtual_network" "oci_connect_vnet" {
  name                = "oci-connect-network"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"
  location            = "${azurerm_resource_group.oci_connect.location}"
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "oci_connect_subnet" {
  name                 = "oci-connect-subnet"
  resource_group_name  = "${azurerm_resource_group.oci_connect.name}"
  virtual_network_name = "${azurerm_virtual_network.oci_connect_vnet.name}"
  address_prefix       = "10.2.1.0/24"
}

resource "azurerm_subnet" "oci_subnet_gw" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.oci_connect.name}"
  virtual_network_name = "${azurerm_virtual_network.oci_connect_vnet.name}"
  address_prefix       = "10.2.2.0/28"
}

resource "azurerm_public_ip" "oci_connect_vng_ip" {
  name                = "oci-connect-vng-ip"
  location            = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "oci_connect_vng" {
  name                = "oci-connect-vng"
  location            = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"
  type                = "ExpressRoute"
  enable_bgp          = true
  sku                 = "Standard"

  ip_configuration {
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.oci_subnet_gw.id}"
    public_ip_address_id          = "${azurerm_public_ip.oci_connect_vng_ip.id}"
  }
}

resource "azurerm_virtual_network_gateway_connection" "oci_conn_vng_gw" {
  name                = "oci-connect-vng-gw"
  location            = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"

  type                       = "ExpressRoute"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.oci_connect_vng.id}"
  express_route_circuit_id   = "${azurerm_express_route_circuit.oci_connect_erc.id}"
}

# this sg is not needed if you rely on the default settings
resource "azurerm_network_security_group" "oci_connect_sg" {
  name                = "oci-connect-securitygroup"
  location            = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"

  security_rule {
    name                       = "InboundAllOCI"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${oci_core_virtual_network.az_connect_vcn.cidr_block}"
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

resource "azurerm_express_route_circuit" "oci_connect_erc" {
  name                  = "oci-connect-expressroute"
  resource_group_name   = "${azurerm_resource_group.oci_connect.name}"
  location              = "${azurerm_resource_group.oci_connect.location}"
  service_provider_name = "Oracle Cloud FastConnect"
  peering_location      = "Washington DC"
  bandwidth_in_mbps     = 50

  sku {
    tier   = "Standard"
    family = "MeteredData"
  }

  allow_classic_operations = false
}

resource "azurerm_route_table" "oci_connect_route_table" {
  name                = "oci-connect-route-table"
  location            = "${azurerm_resource_group.oci_connect.location}"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"
}

resource "azurerm_route" "oci_connect_route" {
  name                = "oci-connect-route"
  resource_group_name = "${azurerm_resource_group.oci_connect.name}"
  route_table_name    = "${azurerm_route_table.oci_connect_route_table.name}"
  address_prefix      = "10.1.0.0/16"
  next_hop_type       = "VirtualNetworkGateway"
}

resource "azurerm_subnet_route_table_association" "oci_connect_route_subnet_association" {
  subnet_id      = "${azurerm_subnet.oci_connect_subnet.id}"
  route_table_id = "${azurerm_route_table.oci_connect_route_table.id}"
}

### oci ###################################################

resource "oci_core_virtual_network" "az_connect_vcn" {
  cidr_block     = "10.1.0.0/16"
  dns_label      = "azconnectvcn"
  compartment_id = "${var.oci_compartment_ocid}"
  display_name   = "az-connect-vcn"
}

resource "oci_core_subnet" "az_connect_subnet" {
  cidr_block        = "10.1.1.0/24"
  compartment_id    = "${var.oci_compartment_ocid}"
  vcn_id            = "${oci_core_virtual_network.az_connect_vcn.id}"
  display_name      = "az-connect-subnet"
  security_list_ids = ["${oci_core_security_list.az_conn_security_list.id}"]
}

resource "oci_core_drg" "az_connect_drg" {
  compartment_id = "${var.oci_compartment_ocid}"
  display_name   = "az-connect-drg"
}

resource "oci_core_drg_attachment" "az_conn_drg_attachment" {
  drg_id       = "${oci_core_drg.az_connect_drg.id}"
  vcn_id       = "${oci_core_virtual_network.az_connect_vcn.id}"
  display_name = "az-connect-drg-attachment"
}

# this sl is not needed if you rely on the default settings
resource "oci_core_security_list" "az_conn_security_list" {
  compartment_id = "${var.oci_compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.az_connect_vcn.id}"
  display_name   = "az-connect-security-list"

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "1"
  }

  ingress_security_rules {
    source   = "10.2.0.0/16"
    protocol = "1"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = "22"
      max = "22"
    }
  }

  ingress_security_rules {
    source   = "10.2.0.0/16"
    protocol = "6"

    tcp_options {
      min = "22"
      max = "22"
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"

    tcp_options {
      min = "80"
      max = "80"
    }
  }

  egress_security_rules {
    destination   = "0.0.0.0/0"
    protocol = "all"
    }

  egress_security_rules {
    destination   = "10.2.0.0/16"
    protocol = "all"
    }

}

resource "oci_core_virtual_circuit" "az_connect_virtual_circuit" {
  display_name         = "az-connect-virtual-circuit"
  compartment_id       = "${var.oci_compartment_ocid}"
  gateway_id           = "${oci_core_drg.az_connect_drg.id}"
  type                 = "PRIVATE"
  bandwidth_shape_name = "1 Gbps"

  # provider service id for azure (asn 12076)
  provider_service_id       = "ocid1.providerservice.oc1.iad.aaaaaaaamdyta753fb6tshj3p2g5zezjwfoki5l46jcaaikxt3hszboiag4q"
  provider_service_key_name = "${azurerm_express_route_circuit.oci_connect_erc.service_key}"

  cross_connect_mappings {
    oracle_bgp_peering_ip   = "10.99.0.201/30"
    customer_bgp_peering_ip = "10.99.0.202/30"
  }

  cross_connect_mappings {
    oracle_bgp_peering_ip   = "10.99.0.205/30"
    customer_bgp_peering_ip = "10.99.0.206/30"
  }
}

resource "oci_core_route_table" "az_test_route_table" {
  display_name   = "az-test-route-table"
  compartment_id = "${var.oci_compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.az_connect_vcn.id}"

  route_rules {
    network_entity_id = "${oci_core_internet_gateway.oci_test_igw.id}"
    destination       = "0.0.0.0/0"
  }

  route_rules {
    network_entity_id = "${oci_core_drg.az_connect_drg.id}"
    destination       = "10.2.0.0/16"
  }
}

resource "oci_core_route_table_attachment" "az_connect_route_table_attachment" {
  subnet_id      = "${oci_core_subnet.az_connect_subnet.id}"
  route_table_id = "${oci_core_route_table.az_test_route_table.id}"
}
