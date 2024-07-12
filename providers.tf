terraform {
  required_version = ">=0.12"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~>3.0"
    }
  }

  backend "azurerm" {
    resource_group_name   = "RampUpChallenge1"
    storage_account_name  = "terraformstatetunefy2"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
# skip_provider_registration = "true"
}

