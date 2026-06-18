location     = "uksouth"
environment  = "prod"
project_name = "ckointapi"

publisher_name  = "Checkout.com Platform Team"
publisher_email = "platform-team@example.com"
alert_email     = "platform-alerts@example.com"

# Kept identical to dev to control assessment cost. In a real production
# rollout, apim_sku_name would move to "Premium_1" or higher (SLA, multi-
# region, VNet injection without the Developer tier's no-SLA caveat), and
# function_service_plan_sku might move to a larger Premium tier (EP2/EP3)
# for headroom and scale-out.
apim_sku_name             = "Developer_1"
function_service_plan_sku = "EP1"

# Distinct, non-overlapping address space from dev so the two environments
# could in principle be peered without conflict.
vnet_address_space                     = ["10.20.0.0/16"]
compute_subnet_address_prefix          = ["10.20.1.0/24"]
private_endpoint_subnet_address_prefix = ["10.20.2.0/24"]
apim_subnet_address_prefix             = ["10.20.3.0/27"]
