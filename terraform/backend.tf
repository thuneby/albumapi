terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.30.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.28"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "stapplicationterraform"
    container_name       = "tfstatefile-apps"
    key                  = "albumapi.tfstate"
  }
}
provider "azurerm" {
  features {}
}