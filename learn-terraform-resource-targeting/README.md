# Learn Terraform Resource Targeting

This repo is a companion repo to the [Terraform Resource Targeting tutorial](https://developer.hashicorp.com/terraform/tutorials/state/resource-targeting).

It contains Terraform configuration you can use to learn how to implement an S3 bucket and bucket objects with Terraform resource targeting.

Target Resources
20min
|
Terraform
Terraform

When you apply changes to your Terraform projects, Terraform generates a plan that includes all of the differences between your configuration and the resources currently managed by your project, if any. When you apply the plan, Terraform will add, remove, and modify resources as proposed by the plan.

In a typical Terraform workflow, you apply the entire plan at once. Occasionally you may want to apply only part of a plan, such as when Terraform's state has become out of sync with your resources due to a network failure, a problem with the upstream cloud platform, or a bug in Terraform or its providers. To support this, Terraform lets you target specific resources when you plan, apply, or destroy your infrastructure. Targeting individual resources can be useful for troubleshooting errors, but should not be part of your normal workflow.

You can use Terraform's -target option to target specific resources, modules, or collections of resources. In this tutorial, you will provision an S3 bucket with some objects in it, then apply changes incrementally with -target.

Prerequisites
You can complete this tutorial using the same workflow with either Terraform OSS or Terraform Cloud. Terraform Cloud is a platform that you can use to manage and execute your Terraform projects. It includes features like remote state and execution, structured plan output, workspace resource summaries, and more.

Select the Terraform Cloud tab to complete this tutorial using Terraform Cloud.


Terraform OSS

Terraform Cloud
This tutorial assumes that you are familiar with the Terraform workflow. If you are new to Terraform, complete the Get Started collection first.

In order to complete this tutorial, you will need the following:

Terraform v1.2+ installed locally.
An AWS account with local credentials configured for use with Terraform.
Note

Some of the infrastructure in this tutorial may not qualify for the AWS free tier. Destroy the infrastructure at the end of the tutorial to avoid unnecessary charges. We are not responsible for any charges that you incur.

Create infrastructure
Clone the example configuration for this tutorial, which defines an S3 bucket with a randomized name, and four S3 bucket objects.

 git clone https://github.com/hashicorp/learn-terraform-resource-targeting.git
Copy
Navigate to the repository directory.

 cd learn-terraform-resource-targeting
Copy

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
Apply this configuration to create your S3 bucket and objects. Confirm the operation by typing yes at the prompt.

 terraform apply

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:
#...

Plan: 12 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn  = (known after apply)
  + bucket_name = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
#...

Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::learning-specially-tender-fawn"
bucket_name = "learning-specially-tender-fawn"
Copy
Tip

This tutorial shows the output for Terraform commands run with OSS. If you are following the Terraform Cloud workflow, the output may differ slightly but the results will be the same.

Target the S3 bucket name
In main.tf, find the random_pet.bucket_name resource. The bucket module uses this resource to assign a randomized name to the S3 bucket. Update the value of length to 5.

main.tf
 resource "random_pet" "bucket_name" {
-  length    = 3
+  length    = 5
   separator = "-"
   prefix    = "learning"
 }
Plan this change.

 terraform plan
#...
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

   aws_s3_object.objects[0] must be replaced
-/+ resource "aws_s3_object" "objects" {
      ~ bucket                 = "learning-newly-still-gibbon" -> (known after apply) # forces replacement
      ~ bucket_key_enabled     = false -> (known after apply)
      ~ etag                   = "fd1573fb94f296502600f23b95493cf4" -> (known after apply)
      ~ id                     = "learning_gladly_incredibly_deeply_growing_condor.txt" -> (known after apply)
      + kms_key_id             = (known after apply)
      - metadata               = {} -> null
      + server_side_encryption = (known after apply)
      ~ storage_class          = "STANDARD" -> (known after apply)
      - tags                   = {} -> null
      + version_id             = (known after apply)
         (6 unchanged attributes hidden)
    }
#...
   module.s3_bucket.aws_s3_bucket_public_access_block.this[0] must be replaced
-/+ resource "aws_s3_bucket_public_access_block" "this" {
      ~ bucket                  = "learning-newly-still-gibbon" -> (known after apply) # forces replacement
      ~ id                      = "learning-newly-still-gibbon" -> (known after apply)
         (4 unchanged attributes hidden)
    }

Plan: 8 to add, 0 to change, 8 to destroy.

Changes to Outputs:
  ~ bucket_arn  = "arn:aws:s3:::learning-newly-still-gibbon" -> (known after apply)
  ~ bucket_name = "learning-newly-still-gibbon" -> (known after apply)

------------------------------------------------------------------------
Copy
Notice how Terraform plans to change the random_pet resource along with any resources dependent on it.

Tip

To change the bucket's name, Terraform must replace the bucket. AWS does not support renaming buckets in place. The AWS provider understands this, and Terraform creates a plan that will replace or update your resources as needed.

Plan the change again, but target only the random_pet.bucket_name resource.

 terraform plan -target="random_pet.bucket_name"
random_pet.bucket_name: Refreshing state... [id=learning-specially-tender-fawn]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

   random_pet.bucket_name must be replaced
-/+ resource "random_pet" "bucket_name" {
      ~ id        = "learning-specially-tender-fawn" -> (known after apply)
      ~ length    = 3 -> 5 # forces replacement
         (2 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ bucket_name = "learning-specially-tender-fawn" -> (known after apply)

Warning: Resource targeting is in effect

#...
Copy
Terraform will plan to replace only the targeted resource.

Now create a plan that targets the module, which will apply to all resources within the module.

 terraform plan -target="module.s3_bucket"
random_pet.bucket_name: Refreshing state... [id=learning-specially-tender-fawn]
module.s3_bucket.aws_s3_bucket.this[0]: Refreshing state... [id=learning-specially-tender-fawn]
module.s3_bucket.aws_s3_bucket_public_access_block.this[0]: Refreshing state... [id=learning-specially-tender-fawn]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

   random_pet.bucket_name must be replaced
-/+ resource "random_pet" "bucket_name" {
      ~ id        = "learning-specially-tender-fawn" -> (known after apply)
      ~ length    = 3 -> 5 # forces replacement
         (2 unchanged attributes hidden)
    }

   module.s3_bucket.aws_s3_bucket.this[0] must be replaced
-/+ resource "aws_s3_bucket" "this" {
      + acceleration_status         = (known after apply)
      ~ arn                         = "arn:aws:s3:::learning-specially-tender-fawn" -> (known after apply)
      ~ bucket                      = "learning-specially-tender-fawn" -> (known after apply) # forces replacement
      ~ bucket_domain_name          = "learning-specially-tender-fawn.s3.amazonaws.com" -> (known after apply)
      ~ bucket_regional_domain_name = "learning-specially-tender-fawn.s3.eu-west-1.amazonaws.com" -> (known after apply)
      ~ hosted_zone_id              = "Z1BKCTXD74EZPE" -> (known after apply)
      ~ id                          = "learning-specially-tender-fawn" -> (known after apply)
      ~ region                      = "eu-west-1" -> (known after apply)
      ~ request_payer               = "BucketOwner" -> (known after apply)
      - tags                        = {} -> null
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)
         (2 unchanged attributes hidden)

      ~ versioning {
          ~ enabled    = false -> (known after apply)
          ~ mfa_delete = false -> (known after apply)
        }
    }

#...

Plan: 4 to add, 0 to change, 4 to destroy.

Changes to Outputs:
  ~ bucket_arn  = "arn:aws:s3:::learning-specially-tender-fawn" -> (known after apply)
  ~ bucket_name = "learning-specially-tender-fawn" -> (known after apply)

Warning: Resource targeting is in effect

#...
Copy
Terraform determines that module.s3_bucket depends on random_pet.bucket_name, and that the bucket name configuration has changed. Because of this dependency, Terraform will update both the upstream bucket name and the module you targeted for this operation. Resource targeting updates resources that the target depends on, but not resources that depend on it.

Note

Terraform creates a dependency graph to determine the correct order in which to apply changes. You can read more about how it works in the Terraform documentation.

Apply the change to only the bucket name. Respond to the confirmation prompt with yes.

 terraform apply -target="random_pet.bucket_name"
random_pet.bucket_name: Refreshing state... [id=learning-specially-tender-fawn]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

   random_pet.bucket_name must be replaced
-/+ resource "random_pet" "bucket_name" {
      ~ id        = "learning-specially-tender-fawn" -> (known after apply)
      ~ length    = 3 -> 5 # forces replacement
         (2 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ bucket_name = "learning-specially-tender-fawn" -> (known after apply)


Warning: Resource targeting is in effect

#...

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

random_pet.bucket_name: Destroying... [id=learning-specially-tender-fawn]
random_pet.bucket_name: Destruction complete after 0s
random_pet.bucket_name: Creating...
random_pet.bucket_name: Creation complete after 0s [id=learning-optionally-violently-apparently-equal-skylark]

Warning: Applied changes may be incomplete

The plan was created with the -target option in effect, so some changes
requested in the configuration may have been ignored and the output values may
not be fully updated. Run the following command to verify that no other
changes are pending:
    terraform plan

Note that the -target option is not suitable for routine use, and is provided
only for exceptional situations such as recovering from errors or mistakes, or
when Terraform specifically suggests to use it as part of an error message.


Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::learning-specially-tender-fawn"
bucket_name = "learning-optionally-violently-apparently-equal-skylark"
Copy
Notice that the bucket_name output changes, and no longer matches the bucket ARN. Open outputs.tf and note that the bucket name output value references the random pet resource, instead of the bucket itself.

outputs.tf
output "bucket_name" {
  description = "Randomly generated bucket name."
  value       = random_pet.bucket_name.id
}
When using Terraform's normal workflow and applying changes to the entire working directory, the bucket name modification would apply to all downstream dependencies as well. Because you targeted the random pet resource, Terraform updated the output value for the bucket name but not the bucket itself. Targeting resources can introduce inconsistencies, so you should only use it in troubleshooting scenarios.

Update the bucket_name output to refer to the actual bucket name.

outputs.tf
 output "bucket_name" {
   description = "Randomly generated bucket name."
-  value       = random_pet.bucket_name.id
+  value       = module.s3_bucket.s3_bucket_id
 }
Because you targeted only part of your configuration in the last operation, your existing resources do not match either the original configuration or the new configuration. Apply changes to the entire working directory to make Terraform update your infrastructure to match the current configuration, including the change you made to the bucket_name output. Confirm the operation by typing yes at the prompt.

 terraform apply
#...
Plan: 7 to add, 0 to change, 7 to destroy.

Changes to Outputs:
  ~ bucket_arn  = "arn:aws:s3:::learning-newly-still-gibbon" -> (known after apply)
  ~ bucket_name = "learning-seriously-lately-hugely-pleasing-newt" -> (known after apply)

------------------------------------------------------------------------

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
#...
Apply complete! Resources: 7 added, 0 changed, 7 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::learning-seriously-lately-hugely-pleasing-newt"
bucket_name = "learning-seriously-lately-hugely-pleasing-newt"
Copy
After using resource targeting to fix problems with a Terraform project, be sure to apply changes to the entire configuration to ensure consistency across all resources. Remember that you can use terraform plan to see any remaining proposed changes.

Target specific bucket objects
Open main.tf and update the contents of the bucket objects. The example configuration uses a single line of example text to represent objects with useful data in them. Change the object contents as shown below.

main.tf
resource "aws_s3_object" "objects"
   count = 4

   acl          = "public-read"
   key          = "${random_pet.object_names[count.index].id}.txt"
   bucket       = module.s3_bucket.s3_bucket_id
-  content      = "Example object #${count.index}"
+  content      = "Bucket object #${count.index}"
   content_type = "text/plain"
}
You can pass multiple -target options to target several resources at once. Apply this change to two of the bucket object and confirm with a yes.

 terraform apply -target="aws_s3_object.objects[2]" -target="aws_s3_object.objects[3]"
#...
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

   aws_s3_object.objects[2] will be updated in-place
  ~ resource "aws_s3_object" "objects" {
      ~ content            = "Example object #2" -> "Bucket object #2"
        id                 = "learning_overly_subtly_suitably_flexible_goldfish.txt"
        tags               = {}
      + version_id         = (known after apply)
         (10 unchanged attributes hidden)
    }

   aws_s3_object.objects[3] will be updated in-place
  ~ resource "aws_s3_object" "objects" {
      ~ content            = "Example object #3" -> "Bucket object #3"
        id                 = "learning_informally_blatantly_jolly_worthy_crappie.txt"
        tags               = {}
      + version_id         = (known after apply)
         (10 unchanged attributes hidden)
    }

Plan: 0 to add, 2 to change, 0 to destroy.
╷
│ Warning: Resource targeting is in effect
│
│ You are creating a plan with the -target option, which means that the
│ result of this plan may not represent all of the changes requested by the
│ current configuration.
│
│ The -target option is not for routine use, and is provided only for
│ exceptional situations such as recovering from errors or mistakes, or when
│ Terraform specifically suggests to use it as part of an error message.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_object.objects[2]: Modifying... [id=learning_overly_subtly_suitably_flexible_goldfish.txt]
aws_s3_object.objects[2]: Modifications complete after 1s [id=learning_overly_subtly_suitably_flexible_goldfish.txt]
aws_s3_object.objects[3]: Modifications complete after 1s [id=learning_informally_blatantly_jolly_worthy_crappie.txt]
╷
│ Warning: Applied changes may be incomplete
│
│ The plan was created with the -target option in effect, so some changes
│ requested in the configuration may have been ignored and the output values
│ may not be fully updated. Run the following command to verify that no other
│ changes are pending:
│     terraform plan
│
│ Note that the -target option is not suitable for routine use, and is
│ provided only for exceptional situations such as recovering from errors or
│ mistakes, or when Terraform specifically suggests to use it as part of an
│ error message.
╵

Apply complete! Resources: 0 added, 2 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::learning-seriously-lately-hugely-pleasing-newt"
bucket_name = "learning-seriously-lately-hugely-pleasing-newt"
Copy
Terraform updated the selected bucket objects and notified you that the changes to your infrastructure may be incomplete.

Target bucket object names
As shown above, you can target individual instances of a collection created using the count or for_each meta-arguments. However, Terraform calculates resource dependencies for the entire resource. In some cases, this can lead to surprising results.

Remove the prefix argument from the random_pet.object_names resource in main.tf.

main.tf
 resource "random_pet" "object_names" {
   count = 4

   length    = 5
   separator = "_"
-  prefix    = "learning"
 }
Attempt to apply this change to a single bucket object.

 terraform apply -target="aws_s3_object.objects[2]"
#...
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

   aws_s3_object.objects[2] must be replaced
-/+ resource "aws_s3_object" "objects" {
      ~ bucket_key_enabled     = false -> (known after apply)
      ~ etag                   = "ac6265d2157e71b8e8470b465ddb45db" -> (known after apply)
      ~ id                     = "learning_overly_subtly_suitably_flexible_goldfish.txt" -> (known after apply)
      ~ key                    = "learning_overly_subtly_suitably_flexible_goldfish.txt" -> (known after apply) # forces replacement
      + kms_key_id             = (known after apply)
      - metadata               = {} -> null
      + server_side_encryption = (known after apply)
      ~ storage_class          = "STANDARD" -> (known after apply)
      - tags                   = {} -> null
      + version_id             = (known after apply)
         (6 unchanged attributes hidden)
    }

   random_pet.object_names[0] must be replaced
-/+ resource "random_pet" "object_names" {
      ~ id        = "learning_gladly_incredibly_deeply_growing_condor" -> (known after apply)
      - prefix    = "learning" -> null # forces replacement
         (2 unchanged attributes hidden)
    }

   random_pet.object_names[1] must be replaced
-/+ resource "random_pet" "object_names" {
      ~ id        = "learning_nationally_carefully_firstly_huge_whippet" -> (known after apply)
      - prefix    = "learning" -> null # forces replacement
         (2 unchanged attributes hidden)
    }

   random_pet.object_names[2] must be replaced
-/+ resource "random_pet" "object_names" {
      ~ id        = "learning_overly_subtly_suitably_flexible_goldfish" -> (known after apply)
      - prefix    = "learning" -> null # forces replacement
         (2 unchanged attributes hidden)
    }

   random_pet.object_names[3] must be replaced
-/+ resource "random_pet" "object_names" {
      ~ id        = "learning_informally_blatantly_jolly_worthy_crappie" -> (known after apply)
      - prefix    = "learning" -> null # forces replacement
         (2 unchanged attributes hidden)
    }

Plan: 5 to add, 0 to change, 5 to destroy.

Warning: Resource targeting is in effect

You are creating a plan with the -target option, which means that the result
of this plan may not represent all of the changes requested by the current
configuration.

The -target option is not for routine use, and is provided only for
exceptional situations such as recovering from errors or mistakes, or when
Terraform specifically suggests to use it as part of an error message.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
Copy
Notice that Terraform updated all five of the random_pet.object_name resources, not just the name of the object you targeted. Both random_pet.object_name and aws_s3_object.object use count to provision multiple resources, and each bucket object refers to the name of the same index. However, because the entire aws_s3_bucket_objects.objects resource depends on the entire random_pet.object_names resource, Terraform updated all the names.

Accept the change with a yes.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_s3_bucket_object.objects[2]: Destroying... [id=learning_brightly_strangely_naturally_willing_aardvark.txt]
aws_s3_bucket_object.objects[2]: Destruction complete after 1s
random_pet.object_names[2]: Destroying... [id=learning_brightly_strangely_naturally_willing_aardvark]
##...

Apply complete! Resources: 5 added, 0 changed, 5 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::learning-optionally-violently-apparently-equal-skylark"
bucket_name = "learning-optionally-violently-apparently-equal-skylark"
Copy
Destroy your infrastructure
Terraform's destroy command also accepts resource targeting. In the examples above, you referred to individual bucket objects with their index in square brackets, such as aws_s3_bucket_object.objects[2]. You can also refer to the entire collection of resources at once. Destroy the bucket objects, and respond to the confirmation prompt with a yes.

 terraform destroy -target="aws_s3_object.objects"
#...
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

   aws_s3_object.objects[0] will be destroyed
#...
Plan: 0 to add, 0 to change, 4 to destroy.


Warning: Resource targeting is in effect

You are creating a plan with the -target option, which means that the result
of this plan may not represent all of the changes requested by the current
configuration.

The -target option is not for routine use, and is provided only for
exceptional situations such as recovering from errors or mistakes, or when
Terraform specifically suggests to use it as part of an error message.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_s3_bucket_object.objects[3]: Destroying... [id=learning_rationally_lately_slowly_careful_warthog.txt]
aws_s3_bucket_object.objects[1]: Destroying... [id=learning_partially_eminently_intensely_elegant_worm.txt]
aws_s3_bucket_object.objects[2]: Destroying... [id=mostly_manually_certainly_cheerful_quetzal.txt]
aws_s3_bucket_object.objects[0]: Destroying... [id=learning_firmly_smoothly_firmly_dashing_bonefish.txt]
aws_s3_bucket_object.objects[2]: Destruction complete after 1s
aws_s3_bucket_object.objects[3]: Destruction complete after 1s
aws_s3_bucket_object.objects[0]: Destruction complete after 1s
aws_s3_bucket_object.objects[1]: Destruction complete after 1s

Warning: Applied changes may be incomplete

The plan was created with the -target option in effect, so some changes
requested in the configuration may have been ignored and the output values may
not be fully updated. Run the following command to verify that no other
changes are pending:
    terraform plan

Note that the -target option is not suitable for routine use, and is provided
only for exceptional situations such as recovering from errors or mistakes, or
when Terraform specifically suggests to use it as part of an error message.


Destroy complete! Resources: 4 destroyed.
Copy
Now destroy the rest of your infrastructure. Respond to the confirmation prompt with yes.

 terraform destroy
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:
#...
Plan: 0 to add, 0 to change, 8 to destroy.

Changes to Outputs:
  - bucket_arn  = "arn:aws:s3:::learning-seriously-lately-hugely-pleasing-newt" -> null
  - bucket_name = "learning-seriously-lately-hugely-pleasing-newt" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

#...
Apply complete! Resources: 0 added, 0 changed, 8 destroyed.
Copy
If you used Terraform Cloud for this tutorial, after destroying your resources, delete the learn-terraform-resource-targeting workspace from your Terraform Cloud organization.
