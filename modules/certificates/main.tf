# Self-signed Certificate Authority used purely for this assessment's mTLS
# demo. In a real environment this would be replaced by an internal PKI
# (e.g. an Azure-integrated CA or HashiCorp Vault PKI) with proper rotation,
# revocation (CRL/OCSP), and key custody controls.

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem       = tls_private_key.ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = var.validity_period_hours

  subject {
    common_name  = var.ca_common_name
    organization = var.ca_organization
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

# Client certificate, signed by the CA above, presented by callers of the
# internal API to satisfy the mTLS requirement.
resource "tls_private_key" "client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name  = var.client_common_name
    organization = var.ca_organization
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.validity_period_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}
