variable "resource_group_name" {
  type        = string
  description = "Resource group for the Storage Account."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "storage_account_name" {
  type        = string
  description = "Globally-unique Storage Account name (lowercase alphanumeric, 3-24 chars)."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID to host the Storage Account's Private Endpoints."
}

variable "blob_private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for privatelink.blob.core.windows.net."
}

variable "file_private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for privatelink.file.core.windows.net."
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default     = {}
}
