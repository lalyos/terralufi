provider "azurerm" {
  features {}
}
provider "tls" {
}

provider "cloudinit" {
}

data "cloudinit_config" "myconfig" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-config-pkg.yaml", {
      packages = yamlencode(var.packages)
    })
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-config-write.yaml", {
      content = indent(4, templatefile("${path.module}/index.html.tftmpl", {
        title = var.title
        color = var.color
        body  = var.body
      }))
      path = "/var/www/html/index.html"
    })
  }

}


variable "packages" {
  description = "apt packages to install on the VM"
  type        = list(any)
  default     = ["nginx", "git"]
}

variable "title" {
  description = "the h1 header of the index.html page"
  default     = "Terraform Demo"
}

variable "color" {
  description = "the background color of the index.html page"
  default     = "lightblue"
  type        = string
  #  type        = list("blue", "green", "lightblue", "yellow", "orange", "purple", "hotpink", "brown", "white", "cyan", "magenta", "gray", "darkgray", "lightgray", "lime", "olive", "maroon", "navy", "silver", "teal", "fuchsia", "aqua")
}

variable "body" {
  description = "the body of the index.html page"
  default     = "please use title/color/body terraform variables to customize this page"

}
variable "owner" {
    description = "Owner of the resource"
}

variable "costcenter" {
    description = "Cost center of the resource"
}
variable "unumber" {
  description = "Corporate user number"
  validation {
    condition = length(var.unumber) == 7 && substr(var.unumber, 0, 1) == "u"
    error_message = "unumber must start with 'U' followed by 6 digits"
  
  }
}

variable "location" {
  description = "Azure region"
  default = "swedencentral"
}

locals {
  uniq_name = "training-${var.unumber}"
}

resource "azurerm_resource_group" "rg" {
  name     = local.uniq_name
  location = var.location
  tags = {
    owner = var.owner
    costcenter = var.costcenter
  }
}

resource "azurerm_virtual_network" "training" {
  name                = local.uniq_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "training" {
  name                 = local.uniq_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.training.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "training" {
  name                = local.uniq_name
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
  name                = local.uniq_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "adminuser"
  custom_data = base64encode(data.cloudinit_config.myconfig.rendered)
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