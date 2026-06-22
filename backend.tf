terraform {
  backend "s3" {
    bucket         = "aquaos-tfstate-eu-central-1"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "aquaos-terraform-locks"
    encrypt        = true
  }
}
