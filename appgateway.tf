


resource "azurerm_public_ip" "AAG_public_ip" {
  name                = "AAG_public_ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "AAG_tunefy_backend" {
  name                = "backend-appgateway"
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

  frontend_port {
    name = "frontendport"
    port = 3001
  }

  frontend_ip_configuration {
    name                 = "appgateway-frontend-ip"
    public_ip_address_id = azurerm_public_ip.AAG_public_ip.id
  }

  backend_address_pool {
    name = "backendpool"
  }

  backend_http_settings {
    name                  = "httpsettings"
    cookie_based_affinity = "Disabled"
    port                  = 3001
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "httplistener"
    frontend_ip_configuration_name = "appgateway-frontend-ip"
    frontend_port_name             = "frontendport"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routetobackend"
    rule_type                  = "Basic"
    priority                   = 25
    http_listener_name         = "httplistener"
    backend_address_pool_name  = "backendpool"
    backend_http_settings_name = "httpsettings"
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "NIC_AAG_Asso" {
    network_interface_id    = azurerm_network_interface.backend.id
    ip_configuration_name   = "backendIPConfig"
    backend_address_pool_id = tolist(azurerm_application_gateway.AAG_tunefy_backend.backend_address_pool).0.id
}




  
  
