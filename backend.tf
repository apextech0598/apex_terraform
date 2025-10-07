terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "ptwtfstorage001"
    container_name       = "ptwcont"
    key                  = "terraform.tfstate"
  }
}
