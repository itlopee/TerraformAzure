data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
data "azurerm_subscription" "primary" {}

data "azuread_group" "ad" {
  display_name     = "group_studient"
  security_enabled = true
}
data "azurerm_resource_group" "rg-raphd" {
  name = "rg-raphd"
}

output "id" {
  value = data.azurerm_resource_group.rg-raphd.id
}
# data "azurerm_subnet" "appsnet" {
#   name                 = "app01-snet"
#   virtual_network_name = "myriamh-network"
#   resource_group_name  = "rg1-myriamh"
# }

# data "azurerm_subnet" "devopssnet" {
#   name                 = "defaultt"
#   virtual_network_name = "myriamh-network"
#   resource_group_name  = "rg1-myriamh"
# }
