resource "azurerm_resource_group" "serdar-cicd" {
  name     = "serdar-rg"
  location = "West Europe"
}

# RSA key of size 4096 bits
resource "tls_private_key" "serdar" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# eigenes netzwerk
resource "azurerm_virtual_network" "main" {
  name                = "serdar-network"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = "serdar-rg"

}

# subnet
resource "azurerm_subnet" "internal" {
  name                 = "serdar-internal"
  resource_group_name  = "serdar-rg"
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

}

########################### PUBLIC IP #################################

# jenkins public ip
resource "azurerm_public_ip" "jenkins_public_ip" {
  name                = "jenkins-public-ip"
  location            = "West Europe"
  resource_group_name = "serdar-rg"
  allocation_method   = "Dynamic"

}

# webserver public ip
resource "azurerm_public_ip" "webserver_public_ip" {
  name                = "webserver-public-ip"
  location            = "West Europe"
  resource_group_name = "serdar-rg"
  allocation_method   = "Dynamic"

}





######################### NETZWERK ###########################

# netzwerk für den jenkins
resource "azurerm_network_interface" "jenkins" {
  name                = "jenkins-nic"
  location            = "West Europe"
  resource_group_name = "serdar-rg"

  ip_configuration {
    name                          = "serdarcicdnetwork"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_public_ip.id
  }

}

resource "azurerm_network_interface_security_group_association" "jenkinsnsg" {
  network_interface_id      = azurerm_network_interface.jenkins.id
  network_security_group_id = azurerm_network_security_group.serdarjenkins-nsg.id

}

# netzwerk für den Server
resource "azurerm_network_interface" "webserver" {
  name                = "webserver-nic"
  location            = "West Europe"
  resource_group_name = "serdar-rg"

  ip_configuration {
    name                          = "servernetwork"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webserver_public_ip.id
  }

}

resource "azurerm_network_interface_security_group_association" "webservernsg" {
  network_interface_id      = azurerm_network_interface.webserver.id
  network_security_group_id = azurerm_network_security_group.serdarserver-nsg.id

}

######################## VM'S KONFIGURATION ############################

#VM1 für Jenkins und Terraform
resource "azurerm_network_security_group" "serdarjenkins-nsg" {
  name                = "serdarjenkins-nsg"
  location            = "West Europe"
  resource_group_name = "serdar-rg"

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_https"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_linux_virtual_machine" "serdarjenkinsvm" {
  name                            = "serdarjenkinsvm"
  resource_group_name             = "serdar-rg"
  location                        = "West Europe"
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  admin_password                  = "serdar123"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.abdulwahab-project-nic1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}


#VM2 für Ansible , server
resource "azurerm_network_security_group" "serdarserver-nsg" {
  name                = "serdarserver-nsg"
  location            = "West Europe"
  resource_group_name = "serdar-rg"

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_https"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_linux_virtual_machine" "serdarservervm" {
  name                            = "serdarservervm"
  resource_group_name             = "serdar-rg"
  location                        = "West Europe"
  size                            = "Standard_B2s"
  admin_username                  = "azureuser"
  admin_password                  = "serdar123"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.abdulwahab-project-nic2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
