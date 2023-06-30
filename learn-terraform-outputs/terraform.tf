# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {

	cloud {
			organization = "level4-com-ng"
			workspaces {
				name = "learn-terraform-outputs"
			}
	}
	

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.43.0"
    }
  }

  required_version = "~> 1.4.6"
}
