output "public_ip" {
  value = azurerm_container_group.laravel.ip_address
}