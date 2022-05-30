# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.70.0"
  }
    }
  }


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
resource "azurerm_resource_group" "rg" {
  name     = "rg1-myriamh"
  location = "West Europe"
}
resource "azurerm_storage_account" "sa" {
  name                     = "storageaccountmyriamh"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "sc" {
  name                  = "sc1-myriamh"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_mssql_server" "mssql_server" {
  name                         = "myriamh-sqlserver1"
  resource_group_name          = data.azurerm_resource_group.rg-raphd.name
  location                     = data.azurerm_resource_group.rg-raphd.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_log_analytics_workspace" "law" {
#   count               = 3
#   name                = "myriamhlaw${count.index}"
    name              = "myriamhlaw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

 
}

resource "azurerm_monitor_diagnostic_setting" "mds" {
  name               = "myriamh-mds"
  target_resource_id = azurerm_key_vault.key_vault.id
#   storage_account_id = azurerm_storage_account.sa.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id 

  log {
    category = "AuditEvent"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

#   metric {
#     category = "AllMetrics"

#     retention_policy {
#       enabled = false
#     }
#   }
}
# subnet which it will be used to creare the private endpoint#

resource "azurerm_virtual_network" "vnet" {
  name                = "myriamh-network"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
  
  tags = {
    environment = "dev"
  }
}
 
resource "azurerm_subnet" "appsnet" {
  name                 = "app01-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  enforce_private_link_endpoint_network_policies = true 
  service_endpoints                              = ["Microsoft.KeyVault"]

#   delegation {
#     name = "delegation"

#     service_delegation {
#       name    = "Microsoft.ContainerInstance/containerGroups"
#       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
#     }
#   }
}
resource "azurerm_subnet" "devopssnet" {
  name                 = "defaultt"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  enforce_private_link_endpoint_network_policies = true
  service_endpoints                              = ["Microsoft.KeyVault"]

}

# Create Key vault#
resource "azurerm_key_vault" "key_vault" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.sku_name
  tags                            = var.tags
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  timeouts {
    delete = "60m"
  }
access_policy {
#to provide the current user with access to Key vault
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "create",
      "get",
      "create",
      "list"
    ]
    certificate_permissions = [
      "create",
      "get",
      "create",
      "list"
    ]
    secret_permissions = [
      "set",
      "get",
      "delete",
      "purge",
      "recover"
    ]
  }
#prvent external access/ from other subnet not declared in variables file#
  network_acls {
    bypass                     = var.bypass
    default_action             = var.default_action
    ip_rules                   = var.ip_rules
    virtual_network_subnet_ids = [azurerm_subnet.appsnet.id,azurerm_subnet.devopssnet.id]
  }
  lifecycle {
      ignore_changes = [
          tags
      ]
  }
}

# Create Private endpoint#
resource "azurerm_private_endpoint" "private_endpoint" {
  name                = var.private_end_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = "${azurerm_subnet.appsnet.id}"
  tags                = var.tags
  private_service_connection {
    name                           = "${var.name}Connection"
    private_connection_resource_id = azurerm_key_vault.key_vault.id
    is_manual_connection           = var.is_manual_connection
    subresource_names              = try([var.subresource_name], null)
    request_message                = try(var.request_message, null)
  }
#   private_dns_zone_group {
#     name                 = var.private_dns_zone_group_name
#     private_dns_zone_ids = [azurerm_private_dns_zone.main.id]
#   }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
  depends_on = [azurerm_key_vault.key_vault]
}
#Create Private DNS Zone#
# resource "azurerm_private_dns_zone" "main" {
#   name                = "privatelink.vaultcore.azure.net"
#   resource_group_name = var.resource_group_name
# }
# create vms with for each 
# resource "azurerm_virtual_network" "vnet1" {
#   name                = var.vnet_name
#   location            = var.location1
#   resource_group_name = var.rg_name
#   address_space       = var.address_space
# }

# resource "azurerm_subnet" "subnet" {
#   for_each = var.subnet

#   name                 = each.value["name"]
#   resource_group_name  = each.value["resource_group_name"]
#   virtual_network_name = each.value["virtual_network_name"]
#   address_prefixes     = each.value["address_prefixes"]
#   depends_on           = [azurerm_virtual_network.vnet1]
# }

# locals {
#   subnets = {
#     for key, value in azurerm_subnet.subnet : key => value
#   }
# }

# output "app_subnet" {
#   value = lookup(local.subnets, "app_subnet", "not_found")
# }

# Create Private endpoint for mssql 
resource "azurerm_private_endpoint" "private_endpoint_mssql" {
  name                = "myriamh_private_endpoint_mssql"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = "${azurerm_subnet.appsnet.id}"
  tags                = var.tags
  private_service_connection {
    name                           = "${var.name}Connection"
    private_connection_resource_id = azurerm_mssql_server.mssql_server.id
    is_manual_connection           = var.is_manual_connection
    subresource_names              = ["sqlServer"]
   
  }
}

#  Create a Windows Virtual Machine
 
resource "azurerm_network_interface" "main" {
  name                = "ni-myriamh"
  location            = var.location
  resource_group_name = var.resource_group_name
 
  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.appsnet.id}"
    private_ip_address_allocation = "dynamic"
    # public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
  }
}
 
# resource "azurerm_public_ip" "publicip" {
#     name                         = "myPublicIP"
#     location                     = "UK South"
#     resource_group_name          = "${azurerm_resource_group.RG.name}"
#     public_ip_address_allocation = "static"
 
# }
 
resource "azurerm_virtual_machine" "test" {
  name                  = "Server01"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_B1ls"
  # availability_set_id   = "${azurerm_availability_set.AS1.id}"
    
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true
 
  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true
 
storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2012-R2-Datacenter"
    version   = "latest"
  }
   
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
 
  os_profile {
    computer_name  = "Server01"
    admin_username = "techpro"
    admin_password = "Password1234!"
  }
   
   os_profile_windows_config {
     enable_automatic_upgrades = false
   }
    
#  tags {
#     environment = "Production"
#   }
}

  resource "azurerm_mssql_database" "test" {
  name           = "myriamh-db-d"
  server_id      = azurerm_mssql_server.mssql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  auto_pause_delay_in_minutes = -1
  min_capacity                = 0.5
  read_replica_count          = 0
  read_scale                  = false
  sku_name       = "GP_S_Gen5_1"
  zone_redundant = false
  short_term_retention_policy {
    retention_days = 14
  }
  threat_detection_policy {
        disabled_alerts      = []
        email_account_admins = "Disabled"
        email_addresses      = []
        retention_days       = 0
        state                = "Disabled"
        use_server_default   = "Disabled"
    }
  }
# module "sql-database" {
#   source              = "Azure/database/azurerm"
#   resource_group_name = "rg1-myriamh"
#   location            = "West Europe"
#   db_name             = "mydatabase"
#   sql_admin_username  = "mradministrator"
#   sql_password        = "P@ssw0rd12345!"

#   tags             = {
#                         environment = "dev"
#                         costcenter  = "it"
#                       }

# }

# AAD user/ group AAD
resource "azuread_user" "AAD" {
  user_principal_name = "myriamh@deletoilleprooutlook.onmicrosoft.com"
  display_name        = "H. Myriam"
  mail_nickname       = "hmyriam"
  password            = "SecretP@sswd99!"
}
resource "azurerm_role_assignment" "permission" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azuread_user.AAD.object_id
}
# SAS key au niveau container ou storage account 
data "azurerm_storage_account_sas" "myriamhsaskey" {
    connection_string = "${azurerm_storage_account.sa.primary_connection_string}"
    https_only        = true
    resource_types {
        service   = true
        container = true
        object    = true
    }
    services {
        blob  = true
        queue = true
        table = true
        file  = true
    }
    start   = "2022-04-07"
    expiry  = "2022-04-21"
    permissions {
        read    = true
        write   = true
        delete  = true
        list    = true
        add     = true
        create  = true
        update  = true
        process = true
    }
}

output "sas_url_query_string" {
  value = "${data.azurerm_storage_account_sas.myriamhsaskey.sas}"
}

