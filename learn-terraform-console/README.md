## Learn Terraform - The Console Command

The Terraform console provides an interpreter that you can use to evaluate
Terraform expressions and explore your Terraform project's state.

Follow along with this Hashicorp [tutorial](https://developer.hashicorp.com/terraform/tutorials/cli/console).

Develop Configuration with the Console
12min
|
Terraform
Terraform

The Terraform console is an interpreter that you can use to evaluate Terraform expressions and explore your Terraform project's state. The console helps you develop and debug your configuration, especially when working with complex state data and Terraform expressions.

The Terraform console command does not modify your state, configuration files, or resources. It provides a safe way to interactively inspect your existing project's state and evaluate Terraform expressions before incorporating them into your configuration.

In this tutorial, you will deploy an S3 bucket to AWS. Then, you will use the console to inspect your bucket's state. Finally, you will add an IAM policy to your bucket, using the console to help develop the configuration.

Prerequisites
You can complete this tutorial using the same workflow with either Terraform OSS or Terraform Cloud. Terraform Cloud is a platform that you can use to manage and execute your Terraform projects. It includes features like remote state and execution, structured plan output, workspace resource summaries, and more.

Select the Terraform Cloud tab to complete this tutorial using Terraform Cloud.


Terraform OSS

Terraform Cloud
This tutorial assumes that you are familiar with the Terraform workflow. If you are new to Terraform, complete the Get Started tutorials first.

In order to complete this tutorial, you will need the following:

Terraform v1.1+ installed locally.
An AWS account with local credentials configured for use with Terraform.
The AWS CLI (2.0+) installed, and configured for your AWS account.
Note

Some of the infrastructure in this tutorial may not qualify for the AWS free tier. Destroy the infrastructure at the end of the guide to avoid unnecessary charges. We are not responsible for any charges that you incur.

Clone example configuration
Clone the example repository for this tutorial, which contains configuration for you to use to learn how to work with the Terraform console.

 git clone https://github.com/hashicorp/learn-terraform-console.git
Copy
Change to the repository directory.

 cd learn-terraform-console
Copy
Review configuration
Review the configuration in main.tf. After configuring the AWS provider, it defines the S3 bucket you will use for this tutorial.

main.tf
resource "aws_s3_bucket" "data" {
  bucket_prefix = var.bucket_prefix

  force_destroy = true
}

resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl = "private"
}
The configuration defines the bucket prefix as the bucket_prefix variable to ensure a unique bucket name. The force_destroy argument instructs Terraform to delete the bucket contents when you destroy it.

Create S3 bucket

Terraform OSS

Terraform Cloud
Initialize this configuration.

 terraform init

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v3.58.0...
- Installed hashicorp/aws v3.58.0 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
Copy
Apply the configuration to create your S3 bucket. Respond to the confirmation prompt with a yes.

 terraform apply
#...

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + s3_bucket_name = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_bucket.data: Creating...
aws_s3_bucket.data: Still creating... [10s elapsed]
aws_s3_bucket.data: Still creating... [20s elapsed]
aws_s3_bucket.data: Still creating... [30s elapsed]
aws_s3_bucket.data: Still creating... [40s elapsed]
aws_s3_bucket.data: Creation complete after 46s [id=hashilearn-20220419170548709500000001]
data.aws_s3_objects.data_bucket: Reading...
aws_s3_bucket_acl.data: Creating...
data.aws_s3_objects.data_bucket: Read complete after 0s [id=hashilearn-20220419170548709500000001]
aws_s3_bucket_acl.data: Creation complete after 0s [id=hashilearn-20220419170548709500000001,private]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

s3_bucket_name = "hashilearn-20220419170548709500000001"
Copy
Explore Terraform state
Terraform's console loads your project's state and allows you to interactively evaluate Terraform expressions before using them in your configuration. Launch the console now.

 terraform console
>
Copy
Note

The Terraform console uses a > prompt, which is not displayed in the code blocks below.

Get the state of the aws_s3_bucket.data resource by pasting its resource ID into the console prompt.

aws_s3_bucket.data
Copy
The console will print out the state of the aws_s3_bucket.data resource.

{
  "acceleration_status" = ""
  "acl" = tostring(null)
  "arn" = "arn:aws:s3:::hashilearn-20220419170548709500000001"
  "bucket" = "hashilearn-20220419170548709500000001"
  "bucket_domain_name" = "hashilearn-20220419170548709500000001.s3.amazonaws.com"
  "bucket_prefix" = "hashilearn-"
  "bucket_regional_domain_name" = "hashilearn-20220419170548709500000001.s3.us-west-2.amazonaws.com"
  "cors_rule" = tolist([])
  "force_destroy" = true
  "grant" = toset([
    {
      "id" = "ecab6471f6a5f070cb98fac03e10bed57122c3459fef07409dd0705db45433dc"
      "permissions" = toset([
        "FULL_CONTROL",
      ])
      "type" = "CanonicalUser"
      "uri" = ""
    },
  ])
  "hosted_zone_id" = "Z3BJ6K6RIION7M"
  "id" = "hashilearn-20220419170548709500000001"
  "lifecycle_rule" = tolist([])
  "logging" = tolist([])
  "object_lock_configuration" = tolist([])
  "object_lock_enabled" = false
  "policy" = ""
  "region" = "us-west-2"
  "replication_configuration" = tolist([])
  "request_payer" = "BucketOwner"
  "server_side_encryption_configuration" = tolist([])
  "tags" = tomap(null) /* of string */
  "tags_all" = tomap({
    "Environment" = "Test"
    "HashiCorp-Learn" = "aws-default-tags"
    "Service" = "Example"
  })
  "versioning" = tolist([
    {
      "enabled" = false
      "mfa_delete" = false
    },
  ])
  "website" = tolist([])
  "website_domain" = tostring(null)
  "website_endpoint" = tostring(null)
}
Add structured output
In this section, you will create an output value to describe your bucket, and convert it to JSON. Output values enable you to provide data about your Terraform projects to other parts of your infrastructure automation toolchain. To facilitate this, Terraform can print output values in JSON, which is machine-readable.

Systems you integrate with may expect a specific JSON data structure. Use the console to verify that the JSON created matches the required format before you add the output value to your configuration.

First, use the console to create a map that includes your S3 bucket's ARN, ID, and region, and then encode it as JSON with the jsonencode() function.

jsonencode({ arn = aws_s3_bucket.data.arn, id = aws_s3_bucket.data.id, region = aws_s3_bucket.data.region })
Copy
The Terraform console will print out the values of the map you created as a JSON string. Since the console returned the JSON as a string value, it escaped the " characters with the \ prefix.

"{\"arn\":\"arn:aws:s3:::hashilearn-20220419170548709500000001\",\"id\":\"hashilearn-20220419170548709500000001\",\"region\":\"us-west-2\"}"
This JSON matches the intended structure, so add the following to outputs.tf to define an output value using this map.

outputs.tf
Copy
output "bucket_details" {
  description = "S3 bucket details."
  value = {
    arn    = aws_s3_bucket.data.arn,
    region = aws_s3_bucket.data.region,
    id     = aws_s3_bucket.data.id
  }
}
The Terraform console locks your project's state file, so you cannot plan or apply changes while the console is running. Exit the console with <Ctrl-D> or exit.

exit
Copy
Apply the change and respond to the confirmation prompt with a yes. Terraform will now display your new output value.

 terraform apply
#...
Changes to Outputs:
  + bucket_details = {
      + arn    = "arn:aws:s3:::hashilearn-20220419170548709500000001"
      + id     = "hashilearn-20220419170548709500000001"
      + region = "us-west-2"
    }

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes


Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

bucket_details = {
  "arn" = "arn:aws:s3:::hashilearn-20220419170548709500000001"
  "id" = "hashilearn-20220419170548709500000001"
  "region" = "us-west-2"
}
s3_bucket_name = "hashilearn-20220419170548709500000001"

Copy
Output the bucket details as JSON.

 terraform output -json bucket_details
{"arn":"arn:aws:s3:::hashilearn-20220419170548709500000001","id":"hashilearn-20220419170548709500000001","region":"us-west-2"}
Copy
When you include the -json flag in your Terraform output commands, Terraform converts maps and lists to the equivalent JSON data structures.

Set bucket policy
Bucket policies allow you to control access to your S3 buckets and their contents.

In this section, you will apply a policy to your bucket that allows public read access to the objects in the bucket.

Add bucket policy
Add a policy to your bucket. The file bucket_policy.json in the example repository contains a policy based on an example from AWS.

bucket_policy.json
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "PublicRead",
          "Effect": "Allow",
          "Principal": "*",
          "Action": [
              "s3:GetObject",
              "s3:GetObjectVersion"
          ],
          "Resource": [
              "<BUCKET_ARN>/*"
          ]
      }
  ]
}
AWS policies are defined as JSON documents. As a result, the aws_bucket_policy resource expects policies as a JSON string. Using HCL to dynamically generate the policy JSON string enables you to leverage HCL's benefits, such as syntax checking and string interpolation.

Use the Terraform console to convert the policy document to HCL before you incorporate it into your configuration. Use echo to pass the command to the console.

 echo 'jsondecode(file("bucket_policy.json"))' | terraform console
{
  "Statement" = [
    {
      "Action" = [
        "s3:GetObject",
        "s3:GetObjectVersion",
      ]
      "Effect" = "Allow"
      "Principal" = "*"
      "Resource" = [
        "<BUCKET_ARN>/*",
      ]
      "Sid" = "PublicRead"
    },
  ]
  "Version" = "2012-10-17"
}
Copy
The file() function loads the file's content into a string, and jsondecode() converts the string from JSON to an HCL map.

Add the following policy resource to main.tf.

main.tf
Copy
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.data.id

  policy = jsonencode({
  "Statement" = [
    {
      "Action" = [
        "s3:GetObject",
        "s3:GetObjectVersion",
      ]
      "Effect" = "Allow"
      "Principal" = "*"
      "Resource" = [
        "${aws_s3_bucket.data.arn}/*",
      ]
      "Sid" = "PublicRead"
    },
  ]
  "Version" = "2012-10-17"
  })
}
The aws_s3_bucket_policy.public_read resource configures a policy for your bucket based on the policy defined in bucket_policy.json. It replaces the <BUCKET_ARN> placeholder with a reference to your bucket's ARN. Finally, it uses the jsondecode() function to convert the policy back into JSON for use by AWS.

Now, apply this configuration. Respond to the confirmation prompt with a yes to update your bucket policy.

 terraform apply
Terraform will perform the following actions:

   aws_s3_bucket_policy.public_read will be created
  + resource "aws_s3_bucket_policy" "public_read" {
      + bucket = "hashilearn-20220420182934112300000001"
      + id     = (known after apply)
      + policy = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = [
                          + "s3:GetObject",
                          + "s3:GetObjectVersion",
                        ]
                      + Effect    = "Allow"
                      + Principal = "*"
                      + Resource  = [
                          + "arn:aws:s3:::hashilearn-20220420182934112300000001/*",
                        ]
                      + Sid       = "PublicRead"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
    }

Plan: 1 to add, 0 to change, 0 to destroy.


Do you want to perform these actions in workspace "learn-terraform-console"?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_bucket_policy.public_read: Creating...
aws_s3_bucket_policy.public_read: Creation complete after 1s [id=hashilearn-20220420182934112300000001]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_details = {
  "arn" = "arn:aws:s3:::hashilearn-20220420182934112300000001"
  "id" = "hashilearn-20220420182934112300000001"
  "region" = "us-west-2"
}
s3_bucket_name = "hashilearn-20220420182934112300000001"
Copy
Clean up your infrastructure
Remove the infrastructure you created during this tutorial. Respond to the confirmation prompt with a yes.

 terraform destroy
#...
Terraform will perform the following actions:

   aws_s3_bucket.data will be destroyed
  - resource "aws_s3_bucket" "data" {
      - arn                         = "arn:aws:s3:::hashilearn-20220420182934112300000001" -> null
      - bucket                      = "hashilearn-20220420182934112300000001" -> null

#...

Plan: 0 to add, 0 to change, 3 to destroy.

Changes to Outputs:
  - bucket_details = {
      - arn    = "arn:aws:s3:::hashilearn-20220420182934112300000001"
      - id     = "hashilearn-20220420182934112300000001"
      - region = "us-west-2"
    } -> null
  - s3_bucket_name = "hashilearn-20220420182934112300000001" -> null

Do you really want to destroy all resources in workspace "learn-terraform-console"?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_s3_bucket_policy.public_read: Destroying... [id=hashilearn-20220420182934112300000001]
aws_s3_bucket_acl.data: Destroying... [id=hashilearn-20220420182934112300000001,private]
aws_s3_bucket_acl.data: Destruction complete after 0s
aws_s3_bucket_policy.public_read: Destruction complete after 1s
aws_s3_bucket.data: Destroying... [id=hashilearn-20220420182934112300000001]
aws_s3_bucket.data: Destruction complete after 0s

Apply complete! Resources: 0 added, 0 changed, 3 destroyed.
Copy
If you used Terraform Cloud for this tutorial, after destroying your resources, delete the learn-terraform-console workspace from your Terraform Cloud organization.


