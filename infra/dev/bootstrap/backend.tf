terraform {
  backend "s3" {
    bucket         = "andac-tfstate-dev"
    key            = "dev/bootstrap.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "andac-tfstate-lock-dev"
  }
}
