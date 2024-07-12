
output "public_ip_frontend" {
  value = azurerm_public_ip.frontend.ip_address
}


output "public_ip_bastion" {
  value = azurerm_public_ip.bastion.ip_address
}

output "public_ip_gitlab_runner" {
  value = azurerm_public_ip.gitlab_runner.ip_address
}

/*
output "public_ip_AAG_public_ip" {
  value = azurerm_public_ip.AAG_public_ip.ip_address
}
*/

output "dbipaddress" {
  value = azurerm_network_interface.database.private_ip_address
}

output "acr_login_server" {
  value = azurerm_container_registry.my_acr.login_server
}