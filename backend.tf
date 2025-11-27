terraform {
  backend "s3" {
    bucket = "param-bucket-2048-game" # Replace with your actual S3 bucket name
    key    = "EKS/terraform.tfstate"
    region = "ap-south-1"
  }
}
