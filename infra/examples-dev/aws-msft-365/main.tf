terraform {
  required_providers {
    # for the infra that will host Psoxy instances
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.12"
    }

    # for API connections to Microsoft 365
    azuread = {
      version = "~> 2.0"
    }
  }

  # if you leave this as local, you should backup/commit your TF state files
  backend "local" {
  }
}

# NOTE: you need to provide credentials. usual way to do this is to set env vars:
#        AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
# see https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication for more
# information as well as alternative auth approaches
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = var.aws_assume_role_arn
  }
  allowed_account_ids = [
    var.aws_account_id
  ]
}

provider "azuread" {
  tenant_id = var.msft_tenant_id
}

module "psoxy-aws-msft-365" {
  source = "../../modular-examples/aws-msft-365"

  aws_account_id                 = var.aws_account_id
  aws_assume_role_arn            = var.aws_assume_role_arn # role that can test the instances (lambdas)
  aws_region                     = var.aws_region
  psoxy_base_dir                 = var.psoxy_base_dir
  caller_gcp_service_account_ids = var.caller_gcp_service_account_ids
  caller_aws_arns                = var.caller_aws_arns
  enabled_connectors             = var.enabled_connectors
  non_production_connectors      = var.non_production_connectors
  connector_display_name_suffix  = var.connector_display_name_suffix
  custom_bulk_connectors         = var.custom_bulk_connectors
  lookup_table_builders          = var.lookup_table_builders
  msft_tenant_id                 = var.msft_tenant_id
  certificate_subject            = var.certificate_subject
  pseudonymize_app_ids           = var.pseudonymize_app_ids
}

# if you generated these, you may want them to import back into your data warehouse
output "lookup_tables" {
  value = module.psoxy-aws-msft-365.lookup_tables
}

moved {
  from = module.worklytics_connector_specs
  to   = module.psoxy-aws-msft-365.module.worklytics_connector_specs
}

moved {
  from = module.psoxy-aws
  to   = module.psoxy-aws-msft-365.module.psoxy-aws
}

moved {
  from = module.global_secrets
  to   = module.psoxy-aws-msft-365.module.global_secrets
}

moved {
  from = module.msft-connection
  to   = module.psoxy-aws-msft-365.module.msft-connection
}

moved {
  from = module.msft-connection-auth
  to   = module.psoxy-aws-msft-365.module.msft-connection-auth
}

moved {
  from = module.private-key-aws-parameters
  to   = module.psoxy-aws-msft-365.module.msft-365-connector-key-secrets
}

moved {
  from = module.psoxy-msft-connector
  to   = module.psoxy-aws-msft-365.module.psoxy-msft-connector
}

moved{
  from = module.worklytics-psoxy-connection-msft-365
  to   = module.psoxy-aws-msft-365.module.worklytics-psoxy-connection-msft-365
}

moved {
  from = aws_ssm_parameter.long-access-secrets
  to   = module.psoxy-aws-msft-365.aws_ssm_parameter.long-access-secrets
}

moved {
  from = module.parameter-fill-instructions
  to   = module.psoxy-aws-msft-365.module.parameter-fill-instructions
}

moved {
  from = module.source_token_external_todo
  to   = module.psoxy-aws-msft-365.module.source_token_external_todo
}

moved {
  from = module.aws-psoxy-long-auth-connectors
  to   = module.psoxy-aws-msft-365.module.aws-psoxy-long-auth-connectors
}

moved {
  from = module.worklytics-psoxy-connection-oauth-long-access
  to   = module.psoxy-aws-msft-365.module.worklytics-psoxy-connection-oauth-long-access
}

moved {
  from = module.psoxy-bulk
  to   = module.psoxy-aws-msft-365.module.psoxy-bulk
}
