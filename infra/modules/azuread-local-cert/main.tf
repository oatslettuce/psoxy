# generate certificate for Azure AD application locally and deploy it to Azure AD
# NOTE: certificate will only be temporarily written to your local file system, but out of abundance
# of caution should:
#  - run this only in an environment that is approved from key generation in your organization
#  - use a secure location for your Terraform state (eg, not local file systme of your laptop)
terraform {
  required_providers {
    azuread = {
      version = "~> 2.15.0"
    }
  }
}

resource "time_rotating" "rotation" {
  rotation_days = var.rotation_days
}

# done with external as Terraform docs suggest

data "external" "certificate" {
  program     = ["${path.module}/local-cert.sh", var.certificate_subject, var.cert_expiration_days]
}

# for JWT signing
resource "azuread_application_certificate" "certificate" {
  application_object_id = var.application_id
  type                  = "AsymmetricX509Cert"
  value                 = base64decode(data.external.certificate.result.cert)
  end_date              = timeadd(time_rotating.rotation.id, "${var.cert_expiration_days * 24}h")
}

output "private_key_id" {
  value = base64sha256(data.external.certificate.result.key_pkcs8)
}

output "private_key" {
  value = base64decode(data.external.certificate.result.key_pkcs8)
}

# for 3-legged OAuth flows, which believe aren't needed in this case as we have no OIDC/sign-on
# flow for psoxy use-cases
#resource "azuread_application_password" "oauth-client-secret" {
#  application_object_id = var.application_id # oauthClientId
#
#  rotate_when_changed = {
#    rotation = time_rotating.rotation.id
#  }
#}

#output "oauth_client_secret" {
#  value = azuread_application_password.oauth-client-secret.value
#}
