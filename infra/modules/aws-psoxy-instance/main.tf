# provision a Psoxy instance into AWS account

terraform {
  required_providers {
    aws = {
      version = "~> 3.0"
    }
  }
}


# map API gateway request --> lambda function backend
# https://kennbrodhagen.net/2015/12/02/how-to-access-http-headers-using-aws-api-gateway-and-lambda/
resource "aws_apigatewayv2_integration" "map" {
  api_id                    = var.api_gateway.id
  integration_type          = "AWS_PROXY"
  connection_type           = "INTERNET"

  integration_method        = "POST" #TODO: verify that it's also going to pass through GET??
  #TODO: match on subpath equivalent to var.function_name
  integration_uri           = aws_lambda_function.psoxy-instance.invoke_arn
}

# allow API gateway to invoke the lambda function
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "Allow${var.function_name}Invoke"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${var.api_gateway.arn}/*/*/*"

  depends_on = [
    aws_lambda_function.psoxy-instance
  ]
}

resource "aws_lambda_function" "psoxy-instance" {
  function_name = var.function_name
  role          = var.execution_role_arn
  handler       = "co.worklytics.psoxy.Handler"
  runtime       = "java11"
  filename      = var.path_to_function_zip
}

locals {
  proxy_endpoint_url = "${var.api_gateway.api_endpoint}/${var.function_name}"
}


resource "local_file" "todo" {
  filename = "TODO - deploy ${var.function_name}.md"
  content  = <<EOT
First, from `java/core/` within a checkout of the Psoxy repo, package the core proxy library:

```shell
cd ../../java/core
mvn package install
```

Second, from `java/impl/aws` within a checkout of the Psoxy repo, package an executable JAR for the
cloud function with the following command:

```shell
cd ../../java/impl/aws
mvn package
```

Third, run the following deployment command from `java/impl/aws` folder within your checkout:

```shell
sam deploy \
    --template target/deployment
    --region ${var.region} \
    --role-arn ${var.execution_role_arn} \
```

Finally, review the deployed function in AWS console:

TBD

## Testing

If you want to test from your local machine:
```shell
export PSOXY_HOST=${var.api_gateway.api_endpoint}/${var.function_name}
```

NOTE: if you want to customize the rule set used by Psoxy for your source, you can add a
`rules.yaml` file into the deployment directory (`target/deployment`) before invoking the command
above. The rules you define in the YAML file will override the ruleset specified in the codebase for
the source.

EOT
}

output "endpoint_url" {
  value = local.proxy_endpoint_url
}
