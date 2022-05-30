variable "name" {
  description = "(Required) Specifies the name of the key vault."
  type        = string
  default = "myriamhkeyvault"
}
variable "resource_group_name" {
  description = "(Required) Specifies the resource group name of the key vault."
  type        = string
  default = "rg1-myriamh"
}
variable "location" {
  description = "(Required) Specifies the location where the key vault will be deployed."
  type        = string
  default = "West Europe"
}
variable "sku_name" {
  description = "(Required) The Name of the SKU used for this Key Vault. Possible values are standard and premium."
  type        = string
  default     = "standard"
  validation {
    condition = contains(["standard", "premium" ], var.sku_name)
    error_message = "The value of the sku name property of the key vault is invalid."
  }
}

variable "tags" {
  description = "(Optional) Specifies the tags of the log analytics workspace"
  default     = {
    createdWith = "Terraform"
  }
}
variable "enabled_for_deployment" {
  description = "(Optional) Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault. Defaults to false."
  type        = bool
  default     = false
}
variable "enabled_for_disk_encryption" {
  description = " (Optional) Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. Defaults to false."
  type        = bool
  default     = false
}
variable "enabled_for_template_deployment" {
  description = "(Optional) Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault. Defaults to false."
  type        = bool
  default     = false
}
variable "enable_rbac_authorization" {
  description = "(Optional) Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions. Defaults to false."
  type        = bool
  default     = false
}
variable "purge_protection_enabled" {
  description = "(Optional) Is Purge Protection enabled for this Key Vault? Defaults to false."
  type        = bool
  default     = false
}
variable "soft_delete_retention_days" {
  description = "(Optional) The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days."
  type        = number
  default     = 30
}
variable "bypass" {
  description = "(Required) Specifies which traffic can bypass the network rules. Possible values are AzureServices and None."
  type        = string
  default     = "AzureServices"
  validation {
    condition = contains(["AzureServices", "None" ], var.bypass)
    error_message = "The valut of the bypass property of the key vault is invalid."
  }
}
variable "default_action" {
  description = "(Required) The Default Action to use when no rules match from ip_rules / virtual_network_subnet_ids. Possible values are Allow and Deny."
  type        = string
  default     = "Deny"
  validation {
    condition = contains(["Allow", "Deny" ], var.default_action)
    error_message = "The value of the default action property of the key vault is invalid."
  }
}
variable "ip_rules" {
  description = "(Optional) One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault."
  default     = ["89.84.72.169"]
}
variable "virtual_network_subnet_ids" {
  description = "(Optional) One or more Subnet ID's which should be able to access this Key Vault."
  default     = []
}

#####
variable "private_end_name" {
  description = "(Required) Specifies the name of the private endpoint. Changing this forces a new resource to be created."
  type        = string
  default = "Vault01PrivateEndpoint"
}


variable "is_manual_connection" {
  description = "(Optional) Specifies whether the private endpoint connection requires manual approval from the remote resource owner."
  type        = string
  default     = false  
}
variable "subresource_name" {
  description = "(Optional) Specifies a subresource name which the Private Endpoint is able to connect to."
  type        = string
  default     = "vault"
}
variable "request_message" {
  description = "(Optional) Specifies a message passed to the owner of the remote resource when the private endpoint attempts to establish the connection to the remote resource."
  type        = string
  default     = null
}
variable "private_dns_zone_group_name" {
  description = "(Required) Specifies the Name of the Private DNS Zone Group. Changing this forces a new private_dns_zone_group resource to be created."
  type        = string
  default = "KeyVaultPrivateDnsZoneGroup"
}
variable "private_dns" {
  default = {}
}

#variables.tf - for_each resource example
# variable "vnet_name" {
#   type    = string
#   default = "example_vnet"
# }

# variable "rg_name" {
#   type    = string
#   default = "rg1-myriamh"
# }

# variable "location1" {
#   type    = string
#   default = "West US"
# }

# variable "address_space" {
#   type    = list(any)
#   default = ["10.0.0.0/16"]
# }

# variable "subnet" {
#   description = "Map of Azure VNET subnet configuration"
#   type        = map(any)
#   default = {
#     app_subnet = {
#       name                 = "app_subnet"
#       resource_group_name  = "rg1-myriamh"
#       virtual_network_name = "example_vnet"
#       address_prefixes     = ["10.0.1.0/24"]
#     },
#     db_subnet = {
#       name                 = "db_subnet"
#       resource_group_name  = "rg1-myriamh"
#       virtual_network_name = "example_vnet"
#       address_prefixes     = ["10.0.2.0/24"]
#     }
#   }
# }