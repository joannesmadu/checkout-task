variable "resource_group_name" {
  type        = string
  description = "Resource group for APIM."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "apim_name" {
  type        = string
  description = "Globally-unique APIM instance name."
}

variable "publisher_name" {
  type        = string
  description = "APIM publisher organization name (required by Azure)."
}

variable "publisher_email" {
  type        = string
  description = "APIM publisher email (required by Azure)."
}

variable "sku_name" {
  type        = string
  description = "APIM SKU, e.g. Developer_1. Must support Internal VNet mode."
  default     = "Developer_1"
}

variable "apim_subnet_id" {
  type        = string
  description = "Dedicated subnet ID for APIM's Internal VNet injection."
}

variable "function_app_hostname" {
  type        = string
  description = "Default hostname of the backend Function App."
}

variable "ca_certificate_pem" {
  type        = string
  description = "PEM-encoded CA certificate trusted for validating client certificates."
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default     = {}
}
