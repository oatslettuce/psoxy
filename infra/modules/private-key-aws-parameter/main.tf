locals {
  namespace = "PSOXY_${upper(replace(var.instance_id, "-", "_"))}"
}

resource "aws_ssm_parameter" "private-key" {
  name        = "${local.namespace}_PRIVATE_KEY"
  type        = "SecureString"
  description = "Value of private key"
  value       = var.private_key

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_ssm_parameter" "private-key-id" {
  name        = "${local.namespace}_PRIVATE_KEY_ID"
  type        = "SecureString" # probably not necessary
  description = "ID of private key"
  value       = var.private_key_id

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

output "parameters" {
  value = [
    aws_ssm_parameter.private-key-id,
    aws_ssm_parameter.private-key
  ]
}
