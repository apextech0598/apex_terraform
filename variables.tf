variable "resource_group_name" {
  description = "This is default name of resource group"
  type = string
  default = "apex-rg01"

}
variable "location" {
  description = "location of resources"
  type = string
  default = "West Europe"
}
variable "environment" {
  description = "environment"
  type = string
  default = "dev"
}