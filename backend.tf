terraform {
  backend "s3" {
    bucket = "rajashekar-bucket-2048-game"
    key    = "EKS/terraform.tfstate"
    region = "ap-south-1"
  }
}
