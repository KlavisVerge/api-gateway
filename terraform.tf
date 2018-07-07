terraform {
  backend "local" {
    path = "tf_backend/fortnite-api.tfstate"
  }
}

variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_ACCESS_KEY" {}

provider "aws" {
  region     = "us-east-1"
  access_key = "${var.AWS_ACCESS_KEY}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
}

resource "aws_api_gateway_rest_api" "api" {
  name               = "APIs-For-All-API"
  description        = "APIs-For-All APIs"
  binary_media_types = ["multipart/form-data"]
}

resource "aws_api_gateway_resource" "health" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "health"
}

resource "aws_api_gateway_method" "health" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.health.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "health" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.health.id}"
  http_method = "GET"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "health" {
  depends_on  = ["aws_api_gateway_method.health"]
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.health.id}"
  http_method = "${aws_api_gateway_method.health.http_method}"
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "health" {
  depends_on = [
    "aws_api_gateway_integration.health",
    "aws_api_gateway_method_response.health",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.health.id}"
  http_method = "${aws_api_gateway_method.health.http_method}"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS,GET,PUT,PATCH,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_deployment" "APIs" {
  depends_on = [
    "aws_api_gateway_integration_response.health",
  ]

  rest_api_id       = "${aws_api_gateway_rest_api.api.id}"
  stage_name        = "api"
  stage_description = "${timestamp()}"
  description       = "Deployed ${timestamp()}"

  lifecycle {
    create_before_destroy = true
  }
}
