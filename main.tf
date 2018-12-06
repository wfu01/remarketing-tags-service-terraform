provider "aws" {}

variable "environment" {
  type = "string"
}

variable "account_number" {}
variable "hosted_zone" {}

variable "stage" {
  default = "v1"
}

variable "region" {
  type = "string"
}

variable "remarketing_tags_service_get_function_name" {
  default = "get_remarketing_tags"
}

variable "remarketing_tags_service_add_function_name" {
  default = "add_remarketing_tags"
}

variable "remarketing_tags_service_upload_function_name" {
  default = "upload_remarketing_tags"
}

variable "remarketing_tags_service_get_function_handler" {
  default = "app.app"
}

variable "remarketing_tags_service_add_function_handler" {
  default = "app.app"
}

variable "remarketing_tags_service_upload_function_handler" {
  default = "app.app"
}

module "remarketing_tags_service_dynamodb_table" {
  providers = {
    aws = "aws"
  }
  source         = "../../../components/dynamodb"
  table_name     = "provider-account-remarketing-tags"
  read_capacity  = "5"
  write_capacity = "5"
  hash_key       = "ddc_id"
  range_key      = "provider_id"

  attributes = [
    {
      name = "ddc_id"
      type = "S"
    },
    {
      name = "provider_id"
      type = "N"
    },
  ]
}

resource "alks_iamrole" "remarketing_tags_service_lambda_role" {
  name                     = "adv-remarketing-tags-service-lambda-role-${var.environment}"
  type                     = "AWS Lambda"
  include_default_policies = true

}


resource "aws_iam_role_policy" "remarketing_tags_service_lambda_role_policy" {
  name = "remarketing_tags_service-lambda-role-policy-${var.environment}"
  role = "${alks_iamrole.remarketing_tags_service_lambda_role.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1544113406325",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:${var.region}:${var.account_number}:table/${module.remarketing_tags_service_dynamodb_table.table_name}"
    }
  ]
}
EOF
}


module "get_remarketing_tags_lambda" {
  providers = {
    aws = "aws"
  }

  source                    = "remarketing-tags-service-lambda"
  function_name             = "${var.remarketing_tags_service_get_function_name}-${var.environment}"
  handler                   = "${var.remarketing_tags_service_get_function_handler}"
  zip_key                   = "${path.module}/remarketing-tags-service-lambda/adv-remarketing-tags.zip"
  apigw_rest_api_source_arn = "${module.remarketing_tags_service_api-gateway.get_remarketing_tags_rest_api_source_arn}"
  iam_role_arn              = "${alks_iamrole.remarketing_tags_service_lambda_role.arn}"
}

module "add_remarketing_tags_lambda" {
  providers = {
    aws = "aws"
  }

  source                    = "remarketing-tags-service-lambda"
  function_name             = "${var.remarketing_tags_service_add_function_name}-${var.environment}"
  handler                   = "${var.remarketing_tags_service_add_function_handler}"
  zip_key                   = "${path.module}/remarketing-tags-service-lambda/adv-remarketing-tags.zip"
  apigw_rest_api_source_arn = "${module.remarketing_tags_service_api-gateway.add_remarketing_tags_rest_api_source_arn}"
  iam_role_arn              = "${alks_iamrole.remarketing_tags_service_lambda_role.arn}"
}

module "upload_remarketing_tags_lambda" {
  providers = {
    aws = "aws"
  }

  source                    = "remarketing-tags-service-lambda"
  function_name             = "${var.remarketing_tags_service_upload_function_name}-${var.environment}"
  handler                   = "${var.remarketing_tags_service_upload_function_handler}"
  zip_key                   = "${path.module}/remarketing-tags-service-lambda/adv-remarketing-tags.zip"
  apigw_rest_api_source_arn = "${module.remarketing_tags_service_api-gateway.upload_remarketing_tags_rest_api_source_arn}"
  iam_role_arn              = "${alks_iamrole.remarketing_tags_service_lambda_role.arn}"
}

module "remarketing_tags_service_api-gateway" {
  providers = {
    aws = "aws"
  }

  source                             = "remarketing-tags-service-api-gateway"
  api_name                           = "remarketing-tags-service-api-gateway"
  env                                = "${var.environment}"
  account_id                         = "${var.account_number}"
  region                             = "${var.region}"
  get_remarketing_tags_function_name = "${var.remarketing_tags_service_get_function_name}-${var.environment}"
  add_remarketing_tags_function_name = "${var.remarketing_tags_service_add_function_name}-${var.environment}"
  upload_remarketing_tags_function_name = "${var.remarketing_tags_service_upload_function_name}-${var.environment}"
  api_description                    = "Remarketing tags service API"
  stage                              = "${var.stage}"
  hosted_zone                        = "${var.hosted_zone}"

}
