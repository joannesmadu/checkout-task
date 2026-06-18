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

# Note: the metric alert rule itself (e.g. Function App Http5xx) is defined
# in the environment root module rather than here, since it needs to scope
# to the Function App resource and creating that dependency inside this
# module would form a cycle (function_app also depends on this module's
# Application Insights connection string).
