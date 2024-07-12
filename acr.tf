resource "azurerm_container_registry" "my_acr" {
  name                     = "tunefyregistry"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  sku                      = "Basic"
  admin_enabled            = true
}