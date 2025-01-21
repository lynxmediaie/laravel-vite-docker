resource "azurerm_container_group" "laravel" {
  name                = "nginx-container"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  subnet_ids = [azurerm_subnet.subnet.id]

  # container {
  #   cpu    = 0
  #   image  = ""
  #   memory = 0
  #   name   = ""
  # }


  container {
    name   = "nginx"
    image  = "lynxmedia/nginx:0.2"
    cpu    = 0.2
    memory = 0.5

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  image_registry_credential {
    server = "index.docker.io"
    username = "marek@lynxmedia.ie"
    password = "!fGfgvk^lUM4f^ITlg!IuxKhik1G@^Ffp7wCXbDdE@2kF$C1*04oY!CQd$zr^@cBizvH8P^$B98sgfZv9lPItFZ1^g@i4nXLeCJ*Vk2TA1X18uh#SJT9qOD0vjA2M@bq"
  }

}

# resource "azurerm_public_ip" "nginx_public_ip" {
#   name                = "nginx-public-ip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Dynamic"
#   sku                 = "Standard"
# }
#
# resource "azurerm_network_profile" "nginx_network_profile" {
#   name                = "nginx-network-profile"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#
#   container_network_interface {
#     name                = "nginx-interface"
#     public_ip_address_id = azurerm_public_ip.nginx_public_ip.id
#   }
# }