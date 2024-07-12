variable "resource_group_name" {
  default = "tunefy_chall2"
}

variable "location" {
  default = "East US"
}

variable "vnet_address_space" {
  default = "10.0.0.0/16"
}

variable "public_subnet_address_space" {
  default = "10.0.1.0/24"
}

variable "private_subnet_address_space" {
  default = "10.0.2.0/24"
}

variable "management_subnet_address_space" {
  default = "10.0.3.0/24"
}

variable "appgw_subnet_address_space" {
  default = "10.0.4.0/24"
}

variable "frontend_vm_size" {
  default = "Standard_B2s"
}

variable "backend_vm_size" {
  default = "Standard_B1s"
}

variable "db_vm_size" {
  default = "Standard_B1s"
}

variable "bastion_vm_size" {
  default = "Standard_B1s"
}

variable "gitlab_runner_vm_size" {
  default = "Standard_B2s"
}

variable "admin_username" {
  default = "azureuser"
}

variable "pguser" {
  type = string
}

variable "pgdatabase" {
  type = string
}

variable "pgpassword" {
  type = string
}

variable "ai21_token" {
  type = string
}

variable "google_key" {
  type = string
}

variable "token_runner" {
  type = string
}

variable "gitlab_url" {
  default = "https://gitlab.com"
}

