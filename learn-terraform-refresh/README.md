# Learn Terraform - Use Refresh-Only Plans and Applies

This is a companion repository for the [Use Refresh-Only Mode to Sync Terraform
State](https://developer.hashicorp.com/terraform/tutorials/state/refresh) tutorial. It contains Terraform
configuration files for you to use to learn how to safely refresh your Terraform state file.

Use Refresh-Only Mode to Sync Terraform State
9min
|
Terraform
Terraform

Terraform relies on the contents of your workspace's state file to generate an execution plan to make changes to your resources. To ensure the accuracy of the proposed changes, your state file must be up to date.

In Terraform, refreshing your state file updates Terraform's knowledge of your infrastructure, as represented in your state file, with the actual state of your infrastructure. Terraform plan and apply operations run an implicit in-memory refresh as part of their functionality, reconciling any drift from your state file before suggesting infrastructure changes. You can also update your state file without making modifications to your infrastructure using the -refresh-only flag for plan and apply operations.

In this tutorial, you will safely refresh your Terraform state file using the -refresh-only flag. You will also review Terraform's implicit refresh behavior and the advantages of the -refresh-only flag over the deprecated terraform refresh subcommand.

Prerequisites
You can complete this tutorial using the same workflow with either Terraform OSS or Terraform Cloud. Terraform Cloud is a platform that you can use to manage and execute your Terraform projects. It includes features like remote state and execution, structured plan output, workspace resource summaries, and more.

Select the Terraform Cloud tab to complete this tutorial using Terraform Cloud.


Terraform OSS

Terraform Cloud
This tutorial assumes that you are familiar with the Terraform workflow. If you are new to Terraform, complete Get Started tutorials first.

In order to complete this tutorial, you will need the following:

Terraform v1.1+ installed locally.
An AWS account with local credentials configured for use with Terraform.
Note

Some of the infrastructure in this tutorial may not qualify for the AWS free tier. Destroy the infrastructure at the end of the guide to avoid unnecessary charges. We are not responsible for any charges that you incur.

Clone example repository
Clone the sample repository for this tutorial.

 git clone https://github.com/hashicorp/learn-terraform-refresh.git
Copy
Change into the repository directory.

 cd learn-terraform-refresh
Copy
Review configuration
Open main.tf to review the sample configuration. It defines an EC2 instance and a data source to identify the latest Amazon Linux AMI. The provider block references the region input variable, which defaults to us-east-2.

main.tf
provider "aws" {
  region  = var.region

  default_tags {
    tags = {
      hashicorp-learn = "refresh"
    }
  }
}
Create infrastructure

Terraform OSS

Terraform Cloud
Initialize this configuration.

 terraform init
Initializing the backend...
#...
Terraform has been successfully initialized!
You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.
If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
Copy
Apply your configuration. Respond yes to the prompt to confirm the operation.

 terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

   aws_instance.server will be created
  + resource "aws_instance" "server" {
      # ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_instance.server: Creating...
aws_instance.server: Still creating... [10s elapsed]
aws_instance.server: Still creating... [20s elapsed]
aws_instance.server: Creation complete after 22s [id=i-072ef122350d5a3e5]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
Copy
Run a refresh-only plan
A common error scenario that can prompt Terraform to refresh the contents of your state file is mistakenly modifying your credentials or provider configuration. Simulate this situation by updating your AWS provider's region. You will then review the proposed changes to your state file from a Terraform refresh.

Create a terraform.tfvars file in your learn-terraform-refresh directory. Open the file, and paste in the following configuration to override the default region variable.

terraform.tfvars
Copy
region = "us-west-2"
Since you pass the region variable to your AWS provider configuration in main.tf, this will reconfigure your provider for the us-west-2 region. The resources you created earlier are still in us-east-2.

Run terraform plan -refresh-only to review how Terraform would update your state file.

 terraform plan -refresh-only
aws_instance.server: Refreshing state... [id=i-072ef122350d5a3e5]

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the last "terraform apply":

   aws_instance.server has been deleted
  - resource "aws_instance" "server" {
      # ...
    }


This is a refresh-only plan, so Terraform will not take any actions to undo these. If you were expecting these changes then you can apply this plan to
record the updated values in the Terraform state without changing any remote objects.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
Copy
Because you updated your provider for the us-west-2 region, Terraform tries to locate the EC2 instance with the instance ID tracked in your state file but fails to locate it since it's in a different region. Terraform assumes that you destroyed the instance and wants to remove it from your state file.

If the modifications to your state file proposed by a -refresh-only plan were acceptable, you could run a terraform apply -refresh-only and approve the operation to overwrite your state file without modifying your infrastructure. However, in this tutorial, refreshing your state file would drop your resources, so do not run the apply operation.

Review Terraform's refresh functionality
In previous versions of Terraform, the only way to refresh your state file was by using the terraform refresh subcommand. However, this was less safe than the -refresh-only plan and apply mode since it would automatically overwrite your state file without giving you the option to review the modifications first. In this case, that would mean automatically dropping all of your resources from your state file.

The -refresh-only mode for terraform plan and terraform apply operations makes it safer to check Terraform state against real infrastructure by letting you review proposed changes to the state file. It lets you avoid mistakenly removing an existing resource from state and gives you a chance to correct your configuration.

A refresh-only apply operation also updates outputs, if necessary. If you have any other workspaces that use the terraform_remote_state data source to access the outputs of the current workspace, the -refresh-only mode allows you to anticipate the downstream effects.

In order to propose accurate changes to your infrastructure, Terraform first attempts to reconcile the resources tracked in your state file with your actual infrastructure. Terraform plan and apply operations first run an in-memory refresh to determine which changes to propose to your infrastructure. Once you confirm a terraform apply, Terraform will update your infrastructure and state file.

Though Terraform will continue to support the refresh subcommand in future versions, it is deprecated, and we encourage you to use the -refresh-only flag instead. This allows you to review any updates to your state file. Unlike the refresh subcommand, -refresh-only mode is supported in workspaces using Terraform Cloud as a remote backend, allowing your team to collaboratively review any modifications.

Clean up resources
Now that you have reviewed the behavior of the -refresh-only flag, you will destroy the EC2 instance you provisioned.

First, remove your terraform.tfvars file to use default value for the region variable.

 rm terraform.tfvars
Copy
Now run terraform destroy to destroy your infrastructure. Respond yes to the prompt to confirm the operation.

 terraform destroy
aws_instance.server: Refreshing state... [id=i-072ef122350d5a3e5]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

   aws_instance.server will be destroyed
  - resource "aws_instance" "server" {
      # ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_instance.server: Destroying... [id=i-072ef122350d5a3e5]
aws_instance.server: Still destroying... [id=i-072ef122350d5a3e5, 10s elapsed]
aws_instance.server: Still destroying... [id=i-072ef122350d5a3e5, 20s elapsed]
aws_instance.server: Still destroying... [id=i-072ef122350d5a3e5, 30s elapsed]
aws_instance.server: Destruction complete after 31s

Destroy complete! Resources: 1 destroyed.
Copy
If you used Terraform Cloud for this tutorial, after destroying your resources, delete the learn-terraform-refresh workspace from your Terraform Cloud organization.