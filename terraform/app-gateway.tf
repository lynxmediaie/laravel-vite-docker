resource "azurerm_application_gateway" "app_gateway" {
  name                = "app-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    name     = "Basic"
    tier     = "Basic"
    capacity = 1
  }
  gateway_ip_configuration {
    name      = "app-gateway-ip-config"
    subnet_id = azurerm_subnet.gateway-subnet.id
  }
  frontend_ip_configuration {
    name                 = "app-gateway-front-ip"
    public_ip_address_id = azurerm_public_ip.web-gateway-public-ip.id
  }
  backend_address_pool {
    name = "app-gateway-backend-pool"
    ip_addresses = [azurerm_container_group.laravel.ip_address]
  }
  backend_http_settings {
    name                  = "app-gateway-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20

  }
  http_listener {
    name                           = "app-gateway-listener"
    frontend_ip_configuration_name = "app-gateway-front-ip"
    frontend_port_name             = "app-gateway-front-port"
    protocol                       = "Http"
  }
  frontend_port {
    name = "app-gateway-front-port"
    port = 80
  }
  request_routing_rule {
    name                       = "app-gateway-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "app-gateway-listener"
    backend_address_pool_name  = "app-gateway-backend-pool"
    backend_http_settings_name = "app-gateway-http-settings"
    priority = 100
  }
}
