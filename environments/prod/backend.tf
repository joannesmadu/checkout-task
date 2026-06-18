# Remote state in Azure Blob Storage (prod environment).
#
# Uses the same storage account/container as dev but a distinct state key,
# so dev and prod never share or clobber state:
#
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate" \
#     -backend-config="storage_account_name=sttfstateXXXX" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=prod.terraform.tfstate"
#
# See README.md "Remote state" for full bootstrap steps.
terraform {
  backend "azurerm" {}
}
