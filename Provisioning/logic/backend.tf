locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
}


resource "azurerm_lb" "load_balancer_back" {
  name                = "${local.naming_convention}-backlb"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  frontend_ip_configuration {
    name                          = "privateIp"
    subnet_id                     = "${azurerm_subnet.subnet_backend.id}"
    private_ip_address            = "${var.env=="Static"? var.private_ip: null}"
    private_ip_address_allocation = "${var.env=="Static"? "Static": "Dynamic"}"
    
  }
}

resource "azurerm_lb_backend_address_pool" "azurerm_load_balancer_address_pool" {
  name                = "BackEndAddressPool"
  loadbalancer_id     = azurerm_lb.load_balancer_back.id
}

//VPN
resource "azurerm_virtual_wan" "wan" {
  name                = "${local.naming_convention}-wan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
}

resource "azurerm_virtual_hub" "hub" {
  name                = "${local.naming_convention}-hub"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  virtual_wan_id      = azurerm_virtual_wan.wan.id
  address_prefix      = "10.0.2.0/24"
}

resource "azurerm_vpn_gateway" "vpn_gateway" {
  name                = "${local.naming_convention}-vpn"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  virtual_hub_id      = azurerm_virtual_hub.hub.id
}

//Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "azurerm_linux_virtual_machine_scale_set" {
  name                = "${local.naming_convention}-lvmss"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = "distribuidos"
  admin_password      = "AlejandraJhoanAndres212021"
  disable_password_authentication = false


  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${local.naming_convention}-ni"
    primary = true

    ip_configuration {
      name      = "${local.naming_convention}-ipConf"
      primary   = true
      subnet_id = azurerm_subnet.subnet_backend.id
    }
  }
}


resource "azurerm_network_security_group" "azurer_network_security_group_backend" {
  name                = "backend-nsg_aja"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}