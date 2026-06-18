data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name = "standard"

  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.key_vault_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.vault_private_dns_zone_id]
  }
}

# The principal running `terraform apply` needs write access to create the
# secrets below. In CI this would be the OIDC service principal; granted via
# RBAC rather than a legacy access policy.
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "ca_cert" {
  name         = "ca-certificate-pem"
  value        = var.ca_cert_pem
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pem-file"

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "ca_private_key" {
  name         = "ca-private-key-pem"
  value        = var.ca_private_key_pem
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pem-file"

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "client_cert" {
  name         = "client-certificate-pem"
  value        = var.client_cert_pem
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pem-file"

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "client_private_key" {
  name         = "client-private-key-pem"
  value        = var.client_private_key_pem
  key_vault_id = azurerm_key_vault.this.id
  content_type = "application/x-pem-file"

  depends_on = [azurerm_role_assignment.deployer_secrets_officer]
}
