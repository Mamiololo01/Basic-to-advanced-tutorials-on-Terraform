# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Output values

output "s3_bucket_name" {
  description = "Name of our S3 bucket."
  value       = aws_s3_bucket.data.bucket
}

output "bucket_details" {
  description = "S3 bucket details."
  value = {
    arn    = aws_s3_bucket.data.arn,
    region = aws_s3_bucket.data.region,
    id     = aws_s3_bucket.data.id
  }
}
