resource "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"

  tags = var.tags
}

resource "azurerm_monitor_action_group" "this" {
  name                = "ag-internal-api-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "internalapi"

  email_receiver {
    name          = "platform-team"
    email_address = var.action_group_email
  }

  tags = var.tags
}
