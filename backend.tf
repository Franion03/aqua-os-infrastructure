# Uncomment and configure for remote state:
# terraform {
#   backend "s3" {
#     bucket         = "aquaos-terraform-state"
#     key            = "infrastructure/terraform.tfstate"
#     region         = "eu-central-1"
#     dynamodb_table = "aquaos-terraform-locks"
#     encrypt        = true
#   }
# }
