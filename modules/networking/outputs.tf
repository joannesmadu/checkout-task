output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "compute_subnet_id" {
  value = azurerm_subnet.compute.id
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "apim_subnet_id" {
  value = azurerm_subnet.apim.id
}

output "blob_private_dns_zone_id" {
  value = azurerm_private_dns_zone.blob.id
}

output "file_private_dns_zone_id" {
  value = azurerm_private_dns_zone.file.id
}

output "vault_private_dns_zone_id" {
  value = azurerm_private_dns_zone.vault.id
}

output "sites_private_dns_zone_id" {
  value = azurerm_private_dns_zone.sites.id
}
