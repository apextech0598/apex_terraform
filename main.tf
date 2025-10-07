terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.110.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ----------------------------
# VM Names
# ----------------------------
variable "vm_names" {
  description = "VM names"
  type        = list(string)
  default     = ["ptw-srv01", "ptw-srv02"]
}

# ----------------------------
# Resource Group
# ----------------------------
resource "azurerm_resource_group" "ptw_RG" {
  name     = "ptw_RG01"
  location = "West Europe"

  tags = {
    environment = "test"
    project     = "ptw"
  }
}

# ----------------------------
# Virtual Network
# ----------------------------
resource "azurerm_virtual_network" "ptw_vnet" {
  name                = "ptw_vnet01"
  location            = azurerm_resource_group.ptw_RG.location
  resource_group_name = azurerm_resource_group.ptw_RG.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "test"
    project     = "ptw"
  }
}

# ----------------------------
# Subnet
# ----------------------------
resource "azurerm_subnet" "ptw_subnet" {
  name                 = "ptw_subnet01"
  virtual_network_name = azurerm_virtual_network.ptw_vnet.name
  resource_group_name  = azurerm_resource_group.ptw_RG.name
  address_prefixes     = ["10.0.0.0/24"]
}

# ----------------------------
# NSG
# ----------------------------
resource "azurerm_network_security_group" "ptw_nsg" {
  name                = "ptw_nsg01"
  location            = azurerm_resource_group.ptw_RG.location
  resource_group_name = azurerm_resource_group.ptw_RG.name

  tags = {
    environment = "test"
    project     = "ptw"
  }
}

# NSG Rule: Allow RDP from anywhere (⚠️ open to all)
resource "azurerm_network_security_rule" "rdp_rule" {
  name                        = "Allow-RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"   # 👈 allows all IPs
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ptw_RG.name
  network_security_group_name = azurerm_network_security_group.ptw_nsg.name
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "ptw_SGA" {
  subnet_id                 = azurerm_subnet.ptw_subnet.id
  network_security_group_id = azurerm_network_security_group.ptw_nsg.id
}

# ----------------------------
# Public IPs
# ----------------------------
resource "azurerm_public_ip" "ptw_ip" {
  for_each            = toset(var.vm_names)
  name                = "${each.key}-ip"
  location            = azurerm_resource_group.ptw_RG.location
  resource_group_name = azurerm_resource_group.ptw_RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]

  tags = {
    environment = "test"
    project     = "ptw"
  }
}

# ----------------------------
# NICs
# ----------------------------
resource "azurerm_network_interface" "ptw_nic" {
  for_each            = toset(var.vm_names)
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.ptw_RG.location
  resource_group_name = azurerm_resource_group.ptw_RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ptw_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ptw_ip[each.key].id
  }

  tags = {
    environment = "test"
    project     = "ptw"
  }
}

# ----------------------------
# Windows Server 2022 Virtual Machines
# ----------------------------
resource "azurerm_windows_virtual_machine" "ptw_vm" {
  for_each              = toset(var.vm_names)
  name                  = each.key
  location              = azurerm_resource_group.ptw_RG.location
  resource_group_name   = azurerm_resource_group.ptw_RG.name
  size                  = "Standard_D2s_v3"
  admin_username        = "ptwadmin"
  admin_password        = "P@ssword12345!"   # ⚠️ hardcoded password
  network_interface_ids = [azurerm_network_interface.ptw_nic[each.key].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # ✅ Windows Server 2022 Datacenter - latest
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  tags = {
    environment = "test"
    project     = "ptw"
  }
}

# ----------------------------
# Outputs
# ----------------------------
output "vm_public_ips" {
  description = "Public IPs of the deployed VMs"
  value       = { for k, ip in azurerm_public_ip.ptw_ip : k => ip.ip_address }
}
