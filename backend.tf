terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "htwtfstorage001"
    container_name       = "htwcont"
    key                  = "terraform.tfstate"
  }
}
