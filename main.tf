# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg"
  location = "eastus"
}

# Create Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Public IP
resource "azurerm_public_ip" "main" {
    name = "${var.prefix}-publicip"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    allocation_method = "Static"
}

# Create Network Security Group
resource "azurerm_network_security_group" "main" {
    name                = "${var.prefix}-nsg"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    
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

    security_rule {
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Create Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfiguration"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id      = azurerm_network_interface.main.id
    network_security_group_id = azurerm_network_security_group.main.id
}

# Create SSH Key Pair
resource "tls_private_key" "main_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_F2"
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]
  computer_name         = "main"
  admin_username        = var.vm_admin_username
  disable_password_authentication = true
  
  # Set Virtual Machine Public Key
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.main_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  
  # Copy local index.php to remote virtual machine
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.vm_admin_username
      host        = azurerm_public_ip.main.ip_address
      private_key = tls_private_key.main_ssh.private_key_pem
      agent       = false
      timeout     = "2m"
    }
   source      = "index.php"
   destination = "/tmp/index.php"
  }

  # Install apache2 on virtual machine and move index.php to configured location
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.vm_admin_username
      host        = azurerm_public_ip.main.ip_address
      private_key = tls_private_key.main_ssh.private_key_pem
      agent       = false
      timeout     = "2m"
    }
    inline = [
      # Update
      "sudo apt update -y",

      # Create directory apache serves
      "sudo mkdir -p /var/www/html/", # 

      # Install apache
      "sudo apt-get install -y apache2", # install apache2 and php
      "sudo systemctl enable apache2.service", # enable start apache2 on reboots

      # Install php7.2
      "sudo apt update -y",
      "sudo apt install -y software-properties-common",
      "sudo add-apt-repository -y ppa:ondrej/php",
      "sudo apt update -y", # updates
      "sudo apt install -y php7.2",

      # Configure apache php7.2 mod
      "sudo a2enmod php7.2",
      "sudo service apache2 reload",

      # Remove default file from apache installation
      "sudo rm /var/www/html/index.html", 

      # Move index.php (copied over by Terraform "File" provisioner) to the directory apache serves
      "sudo mv /tmp/index.php /var/www/html/index.php" 
      ]
  }
}

# Azure MySQL Server
resource "azurerm_mysql_server" "main" {
  name                              = "${var.prefix}-mysqlserver"
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  administrator_login               = var.mysql_administrator_login
  administrator_login_password      = var.mysql_administrator_login_password
  sku_name                          = "B_Gen5_2"
  storage_mb                        = 5120
  version                           = "5.7"
  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  //public_network_access_enabled   = false
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}