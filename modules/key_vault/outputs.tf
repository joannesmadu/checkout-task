output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "ca_cert_secret_id" {
  value = azurerm_key_vault_secret.ca_cert.versionless_id
}

output "client_cert_secret_id" {
  value = azurerm_key_vault_secret.client_cert.versionless_id
}
