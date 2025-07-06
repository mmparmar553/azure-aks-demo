terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "aks_demo" {
  name     = "rg-aks-demo"
  location = "East US"
  
  tags = {
    Environment = "Demo"
    Project     = "AKS-Istio-ArgoCD"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "vnet-aks-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aks_demo.location
  resource_group_name = azurerm_resource_group.aks_demo.name
  
  tags = {
    Environment = "Demo"
  }
}

# Private Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "subnet-aks-private"
  resource_group_name  = azurerm_resource_group.aks_demo.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public Subnet for Bastion/Jump Host
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "subnet-bastion"
  resource_group_name  = azurerm_resource_group.aks_demo.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group for AKS
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "nsg-aks-demo"
  location            = azurerm_resource_group.aks_demo.location
  resource_group_name = azurerm_resource_group.aks_demo.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
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

# Associate NSG with AKS subnet
resource "azurerm_subnet_network_security_group_association" "aks_nsg_association" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# Private Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acraksdemoprivate${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.aks_demo.name
  location            = azurerm_resource_group.aks_demo.location
  sku                 = "Premium"
  admin_enabled       = false
  
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"
  
  tags = {
    Environment = "Demo"
  }
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Log Analytics Workspace for AKS
resource "azurerm_log_analytics_workspace" "aks_logs" {
  name                = "log-aks-demo-${random_string.suffix.result}"
  location            = azurerm_resource_group.aks_demo.location
  resource_group_name = azurerm_resource_group.aks_demo.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = {
    Environment = "Demo"
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-demo-cluster"
  location            = azurerm_resource_group.aks_demo.location
  resource_group_name = azurerm_resource_group.aks_demo.name
  dns_prefix          = "aks-demo-${random_string.suffix.result}"
  
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  
  default_node_pool {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }

  tags = {
    Environment = "Demo"
  }
}

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                           = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "aks_lb_ip" {
  name                = "pip-aks-demo-lb"
  location            = azurerm_resource_group.aks_demo.location
  resource_group_name = azurerm_resource_group.aks_demo.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Environment = "Demo"
  }
}

# Bastion Host for accessing private cluster
resource "azurerm_public_ip" "bastion_ip" {
  name                = "pip-bastion-demo"
  location            = azurerm_resource_group.aks_demo.location
  resource_group_name = azurerm_resource_group.aks_demo.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = {
    Environment = "Demo"
  }
}

resource "azurerm_network_interface" "bastion_nic" {
  name                = "nic-bastion-demo"
  location            = azurerm_resource_group.aks_demo.location
  resource_group_name = azurerm_resource_group.aks_demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.bastion_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                = "vm-bastion-demo"
  resource_group_name = azurerm_resource_group.aks_demo.name
  location            = azurerm_resource_group.aks_demo.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.bastion_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  tags = {
    Environment = "Demo"
  }
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.aks_demo.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "bastion_public_ip" {
  value = azurerm_public_ip.bastion_ip.ip_address
}

output "load_balancer_ip" {
  value = azurerm_public_ip.aks_lb_ip.ip_address
}
