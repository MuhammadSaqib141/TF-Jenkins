variable "admin_password1" {
  description = "Admin password for the VM"
  type        = string
  default     = "default"
}

output "name" {
  value = var.admin_password1
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "random_password" "example" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}


data "azurerm_key_vault" "example" {
  name                        = "saqib-kv-tf"
  resource_group_name = "saqibrg-secret-rotation"
}

resource "azurerm_key_vault_secret" "example" {
    name         = "test-admin-password"
    value        = var.admin_password1 != "default" ? var.admin_password1 : random_password.example.result
    key_vault_id = data.azurerm_key_vault.example.id
      lifecycle {
      ignore_changes = [
        value,
      ]
  }
}


resource "azurerm_linux_virtual_machine" "example" {
  name                               = "kv-sec-test-machine"
  resource_group_name                = azurerm_resource_group.example.name
  location                           = azurerm_resource_group.example.location
  size                               = "Standard_F2"
  disable_password_authentication    = false
  admin_username                     = "adminuser"
  admin_password                     = var.admin_password1 != "default" ? var.admin_password1 : random_password.example.result

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

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
    lifecycle {
    ignore_changes = [
      admin_password,
    ]
  }
}




