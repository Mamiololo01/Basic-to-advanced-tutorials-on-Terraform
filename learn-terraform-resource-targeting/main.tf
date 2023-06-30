# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      hashicorp-learn = "resource-targeting"
    }
  }
}

resource "random_pet" "bucket_name" {
  length    = 5
  separator = "-"
  prefix    = "learning"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.3.0"

  bucket = random_pet.bucket_name.id
 
}

resource "random_pet" "object_names" {
  count = 4

  length    = 5
  separator = "_"
  #prefix    = "learning"
}

resource "aws_s3_object" "objects" {
  count = 4

  #acl          = "public-read"
  key          = "${random_pet.object_names[count.index].id}.txt"
  bucket       = module.s3_bucket.s3_bucket_id
  content      = "Bucket object #${count.index}"
  content_type = "text/plain"
}
