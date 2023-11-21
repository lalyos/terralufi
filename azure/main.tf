provider "azurerm" {
  features {}
}
provider "tls" {
}

variable "owner" {
    description = "Owner of the resource"
}

variable "costcenter" {
    description = "Cost center of the resource"
}
variable "unumber" {
  description = "Corporate user number"
}

variable "location" {
  description = "Azure region"
  default = "swedencentral"
}

resource "azurerm_resource_group" "rg" {
  name     = "training-${var.unumber}"
  location = var.location
  tags = {
    owner = var.owner
    costcenter = var.costcenter
  }
}

resource "azurerm_virtual_network" "training" {
  name                = "training-${var.unumber}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "training" {
  name                 = "training-${var.unumber}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "training" {
  name                = "training-${var.unumber}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.training.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.unumber}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "webserver" {
  name                = "tls_webserver"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "tls"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_ranges = ["443", "80", "22"]
    destination_address_prefix = azurerm_network_interface.training.private_ip_address
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.training.id
  network_security_group_id = azurerm_network_security_group.webserver.id
}


resource "tls_private_key" "training" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "web" {
  name                = "training-${var.unumber}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.training.id,
  ]

  tags = {
    owner = var.owner
    costcenter = var.costcenter
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.training.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "local_file" "private_key" {
  content  = tls_private_key.training.private_key_pem
  filename = "${path.module}/training_key.pem"
}

output "ssh_command" {
    description = "value of the ssh command"
    value = "ssh -i ${local_file.private_key.filename} ${azurerm_linux_virtual_machine.web.admin_username}@${azurerm_linux_virtual_machine.web.public_ip_address}"
}

output "publicip" {
  description = "value of the public ip"
  value = azurerm_linux_virtual_machine.web.public_ip_address
}