terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "apextfstorage001"
    container_name       = "apexcont"
    key                  = "terraform.tfstate"
  }
}
