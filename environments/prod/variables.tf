variable "location" {
  type        = string
  description = "Azure region to deploy into."
}

variable "environment" {
  type        = string
  description = "Environment name (dev/prod), used in resource naming and tagging."
}

variable "project_name" {
  type        = string
  description = "Short project identifier used as a naming prefix."
  default     = "ckointapi"
}

variable "publisher_name" {
  type        = string
  description = "APIM publisher organization name."
  default     = "Checkout.com Platform Team"
}

variable "publisher_email" {
  type        = string
  description = "APIM publisher email address (required by Azure)."
}

variable "alert_email" {
  type        = string
  description = "Email address notified by the Monitor Action Group."
}

variable "apim_sku_name" {
  type        = string
  description = "APIM SKU. Developer_1 is the cheapest tier supporting Internal VNet mode."
  default     = "Developer_1"
}

variable "function_service_plan_sku" {
  type        = string
  description = "App Service Plan SKU for the Function App."
  default     = "EP1"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space for this environment."
}

variable "compute_subnet_address_prefix" {
  type        = list(string)
  description = "Compute subnet address prefix."
}

variable "private_endpoint_subnet_address_prefix" {
  type        = list(string)
  description = "Private endpoints subnet address prefix."
}

variable "apim_subnet_address_prefix" {
  type        = list(string)
  description = "APIM subnet address prefix (minimum /27)."
}
