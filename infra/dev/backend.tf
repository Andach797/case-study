terraform {
  backend "s3" {
    bucket         = "andac-tfstate-dev"
    key            = "eks/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "andac-tfstate-lock-dev"
  }
}
