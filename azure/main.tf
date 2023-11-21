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
  }
}

resource "tls_private_key" "training" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "web" {
  name                = "training-${var.unumber}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.training.id,
  ]

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