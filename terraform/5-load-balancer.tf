# resource "azurerm_lb" "load_balancer" {
#   name                = "load-balancer"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku                 = "Basic"
#
#   frontend_ip_configuration {
#     name                 = "lb-front-end"
#     public_ip_address_id = azurerm_public_ip.web-gateway-public-ip.id
#   }
# }
#
# resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
#   loadbalancer_id     = azurerm_lb.load_balancer.id
#   name                = "lb-backend-pool"
#   virtual_network_id = azurerm_virtual_network.vnet.id
# }
#
#
# # resource "azurerm_lb_probe" "lb_http_probe" {
# #   loadbalancer_id     = azurerm_lb.load_balancer.id
# #   name                = "http-probe"
# #   protocol            = "Http"
# #   port                = 80
# #   request_path        = "/"
# #   interval_in_seconds = 5
# #   number_of_probes    = 2
# # }
#
# # resource "azurerm_lb_probe" "lb_https_probe" {
# #   loadbalancer_id     = azurerm_lb.load_balancer.id
# #   name                = "https-probe"
# #   protocol            = "Https"
# #   port                = 443
# #   request_path        = "/"
# #   interval_in_seconds = 5
# #   number_of_probes    = 2
# # }
#
# resource "azurerm_lb_rule" "lb_http_rule" {
#   loadbalancer_id                = azurerm_lb.load_balancer.id
#   name                           = "http-rule"
#   protocol                       = "Tcp"
#   frontend_port                  = 80
#   backend_port                   = 80
#   frontend_ip_configuration_name = "lb-front-end"
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
# }
#
# resource "azurerm_lb_rule" "lb_https_rule" {
#   loadbalancer_id                = azurerm_lb.load_balancer.id
#   name                           = "https-rule"
#   protocol                       = "Tcp"
#   frontend_port                  = 443
#   backend_port                   = 443
#   frontend_ip_configuration_name = "lb-front-end"
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
# }