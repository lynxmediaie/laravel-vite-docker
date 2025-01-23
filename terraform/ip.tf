resource "azurerm_public_ip" "web-gateway-public-ip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg.location
  name                = "web-gateway-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}
