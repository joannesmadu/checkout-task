variable "resource_group_name" {
  type        = string
  description = "Resource group for the Function App."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "function_app_name" {
  type        = string
  description = "Globally-unique Function App name."
}

variable "service_plan_sku" {
  type        = string
  description = "SKU for the App Service Plan hosting the Function App. Must support both inbound Private Endpoints and outbound VNet integration reliably together (Elastic Premium, e.g. EP1, or Premium v3)."
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Storage Account backing the Function App (accessed via the Function App's managed identity, no shared key needed)."
}

variable "vnet_integration_subnet_id" {
  type        = string
  description = "Delegated subnet ID for the Function App's outbound VNet integration."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID to host the Function App's inbound Private Endpoint."
}

variable "sites_private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for privatelink.azurewebsites.net."
}

variable "app_insights_connection_string" {
  type        = string
  description = "Application Insights connection string."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default     = {}
}
