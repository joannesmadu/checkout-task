# Remote state in Azure Blob Storage.
#
# Left without hardcoded values so the same code works across environments
# and so storage account names (which must be globally unique) aren't baked
# into version control. Bootstrap the state storage account once (it can't
# be created by the same Terraform run that needs it), then configure via
# `-backend-config` flags or a partial backend config file, e.g.:
#
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate" \
#     -backend-config="storage_account_name=sttfstateXXXX" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=dev.terraform.tfstate"

terraform {
  backend "azurerm" {}
}
