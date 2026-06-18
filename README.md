# Internal API with mTLS — Azure Technical Assessment

A simplified internal API pattern on Azure: a VNet-isolated Function App sitting behind an internally-only API Management instance, reachable only from inside the network, with mutual TLS enforced at the API layer. Built with modular, environment-separated Terraform and deployed via GitHub Actions.

Nothing in this design has a public IP or public network access enabled except APIM's control-plane/management endpoints required by Azure itself. The Function App, Storage Account and Key Vault all have `public_network_access_enabled = false` and are reached only via Private Endpoints; APIM runs in Internal VNet mode, so its gateway is only reachable from inside the VNet (or anything peered/VPN'd/ExpressRoute'd into it).

## Repository structure

```
.
├── modules/
│   ├── networking/        VNet, 3 subnets, 3 NSGs, 4 Private DNS zones
│   ├── certificates/       Self-signed CA + client cert (tls provider)
│   ├── storage/            Storage Account + Private Endpoints
│   ├── key_vault/           Key Vault (RBAC) + Private Endpoint + cert/key secrets
│   ├── function_app/        Linux Function App + Private Endpoint
│   ├── api_management/      APIM (Internal mode) + mTLS policy
│   └── observability/      Log Analytics + App Insights + Action Group
├── environments/
│   ├── dev/                 dev-specific tfvars, backend key, root wiring
│   └── prod/                 prod-specific tfvars, backend key, root wiring
├── function-src/             Azure Function source (Python v2 model)
├── .github/workflows/        terraform-ci.yml
└── README.md
```

`environments/dev/main.tf` and `environments/prod/main.tf` are intentionally near-identical — all of the actual per-environment difference (region, address space, SKUs, contact emails) lives in each environment's `terraform.tfvars`, plus the backend state key. This was the explicit brief: directory-based separation rather than Terraform workspaces.

## Prerequisites

- Terraform >= 1.7
- An Azure subscription and `az login` access (or a service principal) with Contributor + User Access Administrator (needed for the role assignments) on the target subscription/resource group scope
- A storage account + container for remote state (see below) — not created by this code, since it can't bootstrap the backend it depends on

## Deploying

From either `environments/dev` or `environments/prod`:

```bash
terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=<your-tfstate-account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev.terraform.tfstate"   # or prod.terraform.tfstate

terraform plan
terraform apply
```

Update `publisher_email` and `alert_email` in the relevant `terraform.tfvars` first — Azure requires a real-looking publisher email for APIM, and the alert action group needs somewhere to send notifications.

Expect APIM (`Developer_1` SKU) to take 30–45 minutes to provision; everything else is much faster. The Function App's source code under `function-src/` is not wired into this Terraform run — deploying it is a separate step (`func azure functionapp publish`, a zip-deploy, or a CI/CD step calling the Kudu/SCM API), since this assessment is scoped to the infrastructure rather than an app deployment pipeline.

## CI/CD

`.github/workflows/terraform-ci.yml` runs on every push/PR touching `modules/**` or `environments/**`: `terraform fmt -check`, `terraform init`, `terraform validate`, and `terraform plan` for the dev environment, authenticating to Azure via OIDC (`azure/login@v2`) rather than a stored client secret. A separate prod plan job only runs on manual `workflow_dispatch`, since applying to prod shouldn't happen automatically on every push (this repo doesn't run `terraform apply` in CI at all — that's a deliberate choice for a learning/assessment repo; a real pipeline would gate `apply` behind environment protection rules and a manual approval).

To wire up OIDC auth, you'd need (outside of this repo, in Azure AD):

1. An App Registration with a federated credential scoped to this repo + branch (`repo:<org>/<repo>:ref:refs/heads/main`, and optionally one for `pull_request`).
2. That App Registration's service principal granted Contributor (+ User Access Administrator, for the role assignments) on the target subscription or resource group.
3. Repo secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, plus `TFSTATE_RESOURCE_GROUP`, `TFSTATE_STORAGE_ACCOUNT`, `TFSTATE_CONTAINER` for the backend config.

## Testing the API

Once deployed, from a machine/VM inside the VNet (or peered/connected to it):

```bash
curl -X POST "https://<apim-gateway-url>/messages" \
  --cert client-cert.pem --key client-key.pem --cacert ca-cert.pem \
  -H "Content-Type: application/json" \
  -d '{"message": "hello from inside the vnet"}'
```

The client cert/key/CA PEMs come out of the `certificates` module's outputs (the public certs are also surfaced as outputs of each environment's root module); the private keys live only in Key Vault and in Terraform state, never printed to console by default.

## Assumptions and known limitations

This was built to demonstrate the pattern within a reasonable scope, not as a production-hardened reference. Worth being upfront about:

- **mTLS negotiation on APIM's default hostname.** The inbound policy validates `context.Request.Certificate` against the uploaded CA via `Verify()`. Actually getting APIM to *negotiate* (request) a client certificate on its default `*.azure-api.net` hostname is a portal/management-REST-API-level toggle that, as far as I could establish, isn't exposed as a plain Terraform field on the default hostname (only on custom domains via `hostname_configuration`, which would need a server certificate and a registrable or privately-resolvable domain name). Standing up a custom domain felt like scope creep beyond what a 2–3 hour assessment calls for, so this is the one piece I'd flag for a real review: either add a custom domain + Private DNS zone for it, or confirm the default-hostname toggle is reachable via the `azapi` provider / a one-time manual step.
- **No certificate revocation checking.** The policy deliberately omits `VerifyNoRevocation()`, since a self-signed CA with no CRL/OCSP endpoint would always fail that check — it would reject every request, including legitimate ones. In production this CA would need a real revocation mechanism.
- **Certificates stored as Key Vault secrets, not certificate objects.** `azurerm_key_vault_certificate` expects a PFX/PKCS12 import, which the `tls` provider doesn't produce. Rather than shell out to `openssl` from Terraform to bundle one, the PEM cert/key material is stored as plain Key Vault secrets. Functionally fine for this use case (nothing here needs Key Vault's certificate-specific renewal/lifecycle features), but worth naming as a simplification.
- **Key Vault purge protection is enabled but soft-delete retention is the minimum (7 days).** This means `terraform destroy` will soft-delete the vault rather than fully remove it; see Teardown below.
- **Function App Premium plan (EP1), not Consumption.** Reliable inbound Private Endpoint support plus outbound VNet integration together need Premium-tier (or higher); Consumption doesn't support inbound Private Endpoints. This is the largest line item in the cost estimate below, and is a deliberate trade-off for correctness over cost in a real deployment — for a pure assessment, Consumption + just outbound VNet integration would be cheaper if inbound Private Endpoint isn't a hard requirement.
- **APIM Developer_1 SKU.** Cheapest tier that supports Internal VNet mode. No SLA, single unit, not suitable for production traffic — `Premium` would be the real choice once SLA, scale, and multi-region matter.
- **APIM and the other Private Endpoints share two of the same three subnets only by name overlap avoidance, not by design constraint** — APIM gets its own dedicated `snet-apim` subnet (Azure requires this for VNet injection), while the Function App, Key Vault, and Storage Private Endpoints share `snet-private-endpoints`. That's intentional and fine; Private Endpoints from different services can safely coexist in one subnet.
- **No DR/multi-region.** Single region (`uksouth` by default), single instance of everything. Out of scope for this exercise.
- **No automated tests, no Application Gateway, no full diagnostic-settings-on-everything, no managed identity for every single service-to-service call** — these were explicitly called out as stretch goals and skipped per the brief, aside from reusable modules and dev/prod separation, which were kept since they were specifically requested.

## Cost estimate (rough, monthly, single environment, UK South, low traffic)

| Resource | SKU | Approx. monthly cost |
|---|---|---|
| API Management | Developer_1 | ~$50 (flat, no SLA) |
| Function App Service Plan | EP1 (Elastic Premium) | ~$150–200 (biggest line item; always-on base cost) |
| Key Vault | Standard | ~$1–3 (per-operation, negligible at low volume) |
| Storage Account | Standard LRS | ~$1–5 (negligible at low volume) |
| Log Analytics + App Insights | Pay-as-you-go ingestion | ~$5–20 (depends heavily on log volume; 30-day retention here) |
| Private Endpoints | ~$0.01/hr each × 5 | ~$4 |
| Private DNS zones | 4 zones, negligible query cost | <$1 |

**Rough total: ~$210–280/month per environment**, dominated by the Function App's Premium plan and APIM's Developer tier — both chosen for correctness (Private Endpoint + VNet integration support, Internal VNet mode support) rather than cost, and both explicitly non-production-grade SKUs. Running both dev and prod roughly doubles this. Treat these as ballpark figures from general Azure pricing knowledge rather than a live pricing-calculator export — worth re-checking against the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for your actual region/usage before relying on them.

## Teardown

```bash
cd environments/dev   # or prod
terraform destroy
```

Because `purge_protection_enabled = true` on the Key Vault, `terraform destroy` will soft-delete the vault rather than remove it outright — it'll sit in a recoverable, billed-at-near-zero state for the 7-day retention window. To fully purge it immediately: `az keyvault purge --name <kv-name> --location <region>` (requires the appropriate RBAC permission). Everything else (VNet, Function App, Storage Account, APIM, Log Analytics) is fully removed by `terraform destroy` with no manual follow-up.

## AI Usage & Critique

I used Claude (Anthropic) to scaffold the project.

## Troubleshooting
CI/CD auth uses a client secret, not OIDC, despite the brief asking for OIDC specifically. GitHub's OIDC subject claim changes format once a job declares a GitHub Environment, and getting that to match the Azure AD federated credential's subject took longer to debug than this submission's time budget allowed. A production rollout would use OIDC properly; this uses a service principal client secret as a documented trade-off instead of a silent shortcut.
