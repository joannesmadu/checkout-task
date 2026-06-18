variable "resource_group_name" {
  type        = string
  description = "Resource group for the Key Vault."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "key_vault_name" {
  type        = string
  description = "Globally-unique Key Vault name."
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID used for the Key Vault."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID to host the Key Vault's Private Endpoint."
}

variable "vault_private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for privatelink.vaultcore.azure.net."
}

variable "ca_cert_pem" {
  type        = string
  description = "PEM-encoded CA certificate to store as a secret."
}

variable "ca_private_key_pem" {
  type        = string
  description = "PEM-encoded CA private key to store as a secret."
  sensitive   = true
}

variable "client_cert_pem" {
  type        = string
  description = "PEM-encoded client certificate to store as a secret."
}

variable "client_private_key_pem" {
  type        = string
  description = "PEM-encoded client private key to store as a secret."
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default     = {}
}
