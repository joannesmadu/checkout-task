variable "ca_common_name" {
  type        = string
  description = "Common Name for the self-signed Certificate Authority."
  default     = "Internal API CA"
}

variable "ca_organization" {
  type        = string
  description = "Organization name embedded in the CA and client certificate subjects."
  default     = "Checkout.com Assessment"
}

variable "client_common_name" {
  type        = string
  description = "Common Name for the client certificate used for mTLS."
  default     = "internal-api-client"
}

variable "validity_period_hours" {
  type        = number
  description = "Validity period for the generated certificates, in hours."
  default     = 8760 # 1 year
}
