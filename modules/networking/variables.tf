variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy networking resources into."
}

variable "location" {
  type        = string
  description = "Azure region for all networking resources."
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the VNet, e.g. [\"10.10.0.0/16\"]."
}

variable "compute_subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the subnet delegated to the Function App (VNet integration)."
}

variable "private_endpoint_subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the subnet used to host Private Endpoints (Storage, Key Vault, Function App)."
}

variable "apim_subnet_address_prefix" {
  type        = list(string)
  description = "Address prefix for the dedicated APIM internal VNet injection subnet."
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all networking resources."
  default     = {}
}
