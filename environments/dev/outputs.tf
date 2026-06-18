output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "function_app_name" {
  value = module.function_app.function_app_name
}

output "function_app_default_hostname" {
  value = module.function_app.function_app_default_hostname
}

output "apim_name" {
  value = module.api_management.apim_name
}

output "apim_gateway_url" {
  value = module.api_management.apim_gateway_url
}

output "key_vault_uri" {
  value = module.key_vault.key_vault_uri
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "ca_certificate_pem" {
  value       = module.certificates.ca_cert_pem
  description = "Public CA certificate, for reference/import into test clients."
}

output "client_certificate_pem" {
  value       = module.certificates.client_cert_pem
  description = "Public client certificate, for reference. The matching private key is stored in Key Vault and is not output here."
}
