output "ca_cert_pem" {
  value       = tls_self_signed_cert.ca.cert_pem
  description = "PEM-encoded CA certificate (public). Used as the mTLS truststore."
}

output "ca_private_key_pem" {
  value       = tls_private_key.ca.private_key_pem
  description = "PEM-encoded CA private key. Sensitive - only the CA secret holder needs this."
  sensitive   = true
}

output "client_cert_pem" {
  value       = tls_locally_signed_cert.client.cert_pem
  description = "PEM-encoded client certificate (public), presented by API callers for mTLS."
}

output "client_private_key_pem" {
  value       = tls_private_key.client.private_key_pem
  description = "PEM-encoded client private key. Sensitive."
  sensitive   = true
}
