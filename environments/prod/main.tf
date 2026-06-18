locals {
  name_prefix = "${var.project_name}-${var.environment}"
  suffix      = random_string.suffix.result

  tags = {
    environment = var.environment
    project     = "internal-api-mtls"
    managed_by  = "terraform"
  }
}

# Appended to globally-unique resource names (Storage Account, Key Vault,
# Function App, APIM) so re-running this in a fresh subscription, or a
# differently-named fork of this repo, doesn't collide with someone else's
# resources.
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
  numeric = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  vnet_name           = "vnet-${local.name_prefix}"

  vnet_address_space                     = var.vnet_address_space
  compute_subnet_address_prefix          = var.compute_subnet_address_prefix
  private_endpoint_subnet_address_prefix = var.private_endpoint_subnet_address_prefix
  apim_subnet_address_prefix             = var.apim_subnet_address_prefix

  tags = local.tags
}

module "certificates" {
  source = "../../modules/certificates"

  ca_common_name     = "Internal API CA"
  client_common_name = "internal-api-client"
}

module "storage" {
  source = "../../modules/storage"

  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  storage_account_name       = "st${replace(local.name_prefix, "-", "")}${local.suffix}"
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  blob_private_dns_zone_id   = module.networking.blob_private_dns_zone_id
  file_private_dns_zone_id   = module.networking.file_private_dns_zone_id

  tags = local.tags
}

module "observability" {
  source = "../../modules/observability"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  log_analytics_name  = "log-${local.name_prefix}"
  app_insights_name   = "appi-${local.name_prefix}"
  action_group_email  = var.alert_email

  tags = local.tags
}

module "function_app" {
  source = "../../modules/function_app"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  function_app_name   = "func-${local.name_prefix}-${local.suffix}"
  service_plan_sku    = var.function_service_plan_sku

  storage_account_name       = module.storage.storage_account_name
  vnet_integration_subnet_id = module.networking.compute_subnet_id
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  sites_private_dns_zone_id  = module.networking.sites_private_dns_zone_id

  app_insights_connection_string = module.observability.app_insights_connection_string

  tags = local.tags
}

module "key_vault" {
  source = "../../modules/key_vault"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  key_vault_name      = "kv-${replace(local.name_prefix, "-", "")}-${local.suffix}"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  vault_private_dns_zone_id  = module.networking.vault_private_dns_zone_id

  ca_cert_pem            = module.certificates.ca_cert_pem
  ca_private_key_pem     = module.certificates.ca_private_key_pem
  client_cert_pem        = module.certificates.client_cert_pem
  client_private_key_pem = module.certificates.client_private_key_pem

  tags = local.tags
}

module "api_management" {
  source = "../../modules/api_management"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  apim_name           = "apim-${local.name_prefix}-${local.suffix}"
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.apim_sku_name

  apim_subnet_id        = module.networking.apim_subnet_id
  function_app_hostname = module.function_app.function_app_default_hostname
  ca_certificate_pem    = module.certificates.ca_cert_pem

  tags = local.tags
}

###############################################################################
# Cross-module glue
#
# Kept here, rather than inside the modules themselves, to avoid circular
# module dependencies (e.g. function_app <-> key_vault, function_app <->
# observability) while still wiring the access relationships those modules
# need.
###############################################################################

resource "azurerm_role_assignment" "function_storage_blob_owner" {
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = module.function_app.function_app_principal_id
}

resource "azurerm_role_assignment" "function_keyvault_secrets_user" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.function_app.function_app_principal_id
}

resource "azurerm_monitor_metric_alert" "function_http5xx" {
  name                = "alert-${local.name_prefix}-function-http5xx"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [module.function_app.function_app_id]
  description         = "Alerts when the Function App returns an elevated rate of HTTP 5xx responses."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = module.observability.action_group_id
  }

  tags = local.tags
}
