terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "mdu-terraform-state-2026"
    region         = "af-south-1"
    dynamodb_table = "mdu-terraform-locks"
    use_lockfile   = true
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

module "s3" {
  source         = "./modules/s3"
  environment    = var.environment
  project_name   = var.project_name
  aws_account_id = data.aws_caller_identity.current.account_id
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment
  bucket_name = module.s3.bucket_name
}

module "lambda" {
  source               = "./modules/lambda"
  environment          = var.environment
  lambda_role_arn      = module.iam.lambda_role_arn
  bucket_name          = module.s3.bucket_name
  lambda_artifact_path = var.lambda_artifact_path
  log_retention_days   = var.log_retention_days
  aws_region           = var.aws_region
}