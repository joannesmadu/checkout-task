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
