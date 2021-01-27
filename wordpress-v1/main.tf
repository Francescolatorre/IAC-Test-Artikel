provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.40.0"
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "wordpress-resources"
  location = "West Europe"
  tags = {
    createdBy = "francesco"
  }
}


resource "azurerm_virtual_network" "main" {
  name                = "network"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  address_space = ["10.0.0.0/16"]

  tags = {
    createdBy = "francesco"
  }

}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]

}
resource "azurerm_network_security_group" "main" {
  name                = "network-sg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "allow-http-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    description                = "Receice tcp requests on Port 80 -> Forward to 8080"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    source_port_range          = "*"
  } 

  security_rule {
    name                       = "allow-SSH-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    description                = "Receice SSH requests on Port 22"
    destination_address_prefix = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
  
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.wordpressnic.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "main" {
  name                = "public-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  allocation_method = "Dynamic"

  tags = {
    createdBy = "Francesco"
  }
}

resource "azurerm_network_interface" "wordpressnic" {
  name                = "wordpress-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.main.id

  }

}

resource "azurerm_linux_virtual_machine" "wordpressserver" {
  name                            = "wordpress-virtual-machine"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false
  # use free size
  size = "Standard_B1s"

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.wordpressnic.id
  ]
}

data "azurerm_public_ip" "example" {
  name                = azurerm_public_ip.main.name
  resource_group_name = azurerm_resource_group.main.name
  depends_on = [ azurerm_resource_group.main, azurerm_linux_virtual_machine.wordpressserver ]
}

output "public_ip_address" {
  value = data.azurerm_public_ip.example.ip_address
}


