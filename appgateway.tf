resource "azurerm_public_ip" "AAG_public_ip" {
  name                = "AAG_public_ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "AAG_tunefy" {
  name                = "tunefy-appgateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name                 = "appgateway-frontend-ip"
    public_ip_address_id = azurerm_public_ip.AAG_public_ip.id
  }

  # Frontend port for backend
  frontend_port {
    name = "backend-frontend-port"
    port = 3001
  }

  # Frontend port for frontend
  frontend_port {
    name = "frontend-frontend-port"
    port = 80
  }

  # Backend pool for backend
  backend_address_pool {
    name = "backend-pool"
  }

  # Backend pool for frontend
  backend_address_pool {
    name = "frontend-pool"
  }

  # HTTP settings for backend
  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 3001
    protocol              = "Http"
    request_timeout       = 20
  }

  # HTTP settings for frontend
  backend_http_settings {
    name                  = "frontend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 3000
    protocol              = "Http"
    request_timeout       = 20
  }

  # HTTP listener for backend
  http_listener {
    name                           = "backend-http-listener"
    frontend_ip_configuration_name = "appgateway-frontend-ip"
    frontend_port_name             = "backend-frontend-port"
    protocol                       = "Http"
  }

  # HTTP listener for frontend
  http_listener {
    name                           = "frontend-http-listener"
    frontend_ip_configuration_name = "appgateway-frontend-ip"
    frontend_port_name             = "frontend-frontend-port"
    protocol                       = "Http"
  }

  # Request routing rule for backend
  request_routing_rule {
    name                       = "route-to-backend"
    rule_type                  = "Basic"
    priority                   = 25
    http_listener_name         = "backend-http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-http-settings"
  }

  # Request routing rule for frontend
  request_routing_rule {
    name                       = "route-to-frontend"
    rule_type                  = "Basic"
    priority                   = 26
    http_listener_name         = "frontend-http-listener"
    backend_address_pool_name  = "frontend-pool"
    backend_http_settings_name = "frontend-http-settings"
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "NIC_AAG_Backend_Asso" {
    network_interface_id    = azurerm_network_interface.backend.id
    ip_configuration_name   = "backendIPConfig"
    backend_address_pool_id = azurerm_application_gateway.AAG_tunefy.backend_address_pool[0].id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "NIC_AAG_Frontend_Asso" {
    network_interface_id    = azurerm_network_interface.frontend.id
    ip_configuration_name   = "frontendIPConfig"
    backend_address_pool_id = azurerm_application_gateway.AAG_tunefy.backend_address_pool[1].id
}