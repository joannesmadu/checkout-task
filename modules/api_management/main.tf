resource "azurerm_api_management" "this" {
  name                = var.apim_name
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name

  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = var.apim_subnet_id
  }

  tags = var.tags
}

# Uploaded as a CA certificate so the inbound policy below can validate that
# client certificates presented to APIM chain up to this trusted root via
# context.Request.Certificate.Verify().
#
# ASSUMPTION / KNOWN GAP: enabling "negotiate client certificate" on APIM's
# default *.azure-api.net hostname is a portal/management-REST-API toggle
# that, at the time of writing, isn't exposed as a plain Terraform field for
# the *default* hostname (only for custom domains via hostname_configuration,
# which would require a server certificate and DNS we deliberately avoided
# adding here to keep the build within scope - see README "Assumptions").
# This resource and the policy below are written as if that negotiation is
# enabled; in a real rollout this is the one piece to verify/complete by
# hand or via an additional `azapi` provider call.
resource "azurerm_api_management_certificate" "client_ca" {
  name                = "client-ca-certificate"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  data                = base64encode(var.ca_certificate_pem)
}

resource "azurerm_api_management_backend" "function" {
  name                = "internal-api-function-backend"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  protocol            = "http"
  url                 = "https://${var.function_app_hostname}/api/messages"
}

resource "azurerm_api_management_api" "internal_api" {
  name                = "internal-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  revision            = "1"
  display_name        = "Internal Message API"
  path                = "messages"
  protocols           = ["https"]
}

resource "azurerm_api_management_api_operation" "post_message" {
  operation_id        = "post-message"
  api_name            = azurerm_api_management_api.internal_api.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Submit message"
  method              = "POST"
  url_template        = "/"

  request {
    representation {
      content_type = "application/json"
    }
  }
}

# mTLS enforcement: reject any request without a client certificate, or
# whose certificate doesn't verify against the uploaded CA. Deliberately
# omits VerifyNoRevocation(), since that always fails for a self-signed CA
# with no CRL/OCSP endpoint configured - see README "Assumptions".
resource "azurerm_api_management_api_policy" "mtls_validation" {
  api_name            = azurerm_api_management_api.internal_api.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name

  xml_content = <<POLICY
<policies>
  <inbound>
    <choose>
      <when condition="@(context.Request.Certificate == null)">
        <return-response>
          <set-status code="403" reason="Forbidden" />
          <set-body>Client certificate is required.</set-body>
        </return-response>
      </when>
      <when condition="@(!context.Request.Certificate.Verify())">
        <return-response>
          <set-status code="403" reason="Forbidden" />
          <set-body>Client certificate is not trusted.</set-body>
        </return-response>
      </when>
    </choose>
    <set-backend-service backend-id="internal-api-function-backend" />
    <base />
  </inbound>
</policies>
POLICY

  depends_on = [azurerm_api_management_certificate.client_ca]
}
