resource "azurerm_container_group" "laravel" {
  name                = "nginx-container"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  # subnet_ids = [azurerm_subnet.container-subnet.id]
  ip_address_type = "Public"

  container {
    name   = "nginx"
    image  = "lynxmedia/prod-nginx:${var.nginx_tag}"
    cpu    = 0.2
    memory = 0.5

    ports {
      port     = 80
      protocol = "TCP"
    }
    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  image_registry_credential {
    server = var.docker_registry_server
    username = var.docker_registry_username
    password = var.docker_registry_password
  }
}

