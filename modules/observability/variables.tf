variable "resource_group_name" {
  type        = string
  description = "Resource group for observability resources."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "log_analytics_name" {
  type        = string
  description = "Name of the Log Analytics Workspace."
}

variable "app_insights_name" {
  type        = string
  description = "Name of the Application Insights instance."
}

variable "action_group_email" {
  type        = string
  description = "Email address to notify when alerts fire."
}

variable "tags" {
  type        = map(string)
  description = "Common tags."
  default     = {}
}
