# Create a Terraform Plan

This repo is a companion repo to the [Create a Terraform Plan](https://developer.hashicorp.com/terraform/tutorials/cli/plan) tutorial.
It contains Terraform configuration you can use to learn how Terraform generates an execution plan.

The core Terraform workflow consists of three main steps once you have written your Terraform configuration:

Initialize prepares the working directory so Terraform can run the configuration.
Plan lets you preview any changes before you apply them.
Apply executes the changes defined by your Terraform configuration to create, update, or destroy resources.
In order to determine which changes it will make to your infrastructure, Terraform generates an execution plan. To do so, Terraform reconciles your Terraform configuration with the real-world infrastructure tracked in that workspace's state file, and creates a list of resources to create, modify, or destroy. The plan command supports multiple flags that let you modify its behavior which allows you to be flexible in your operations. For example, you can target specific resources rather than your entire configuration, or run refresh-only plans that reconcile your state file with the actual configuration of the resources it tracks.

In this tutorial, you will review how Terraform generates an execution plan, what it contains, and the function of the plan command in a Terraform workflow. To do so, you will create and apply a saved Terraform plan, review its contents, and analyze how a plan reflects changes to your configuration. The saved plan file supports Terraform automation workflows in CI/CD pipelines by guaranteeing that the infrastructure changes Terraform applies match the ones you or your team approve, even if the deploy process completes across different machines or different times.

Prerequisites
The tutorial assumes that you are familiar with Terraform. If you are new to Terraform itself, refer first to the Get Started tutorials. For this tutorial, you will need:

the Terraform 0.14+ CLI installed locally.
Docker.
jq.

Clone the example repository
In your terminal, clone the learn-terraform-plan repository.

 git clone https://github.com/hashicorp/learn-terraform-plan
Copy
Navigate to the cloned repository.

 cd learn-terraform-plan
Copy
Review configuration
The example configuration in this repository creates two Nginx containers through resources and local and public modules. The nginx subdirectory contains the local module used to create one of the containers.

 tree
.
├── LICENSE
├── README.md
├── main.tf
├── nginx
│   ├── main.tf
│   ├── variables.tf
│   └── versions.tf
└── versions.tf
Terraform uses the provider versions specified in the terraform.tf file.

terraform.tf
terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 2.24.0"
    }

    random = {
      source = "hashicorp/random"
      version = "~> 3.4.3"
    }
  }
}
Open the top-level main.tf file. This configuration uses the docker provider to download the latest Nginx image and launch a container using that image.

main.tf
provider "docker" {}
provider "random" {}

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "hello-terraform"

  ports {
    internal = 80
    external = 8000
  }
}
It also references the random_pet resource to generate a pet name. The module.nginx-pet block uses the local nginx module and references the random pet name to create an Nginx container with the pet name.

main.tf
resource "random_pet" "dog" {
  length = 2
}

module "nginx-pet" {
  source = "./nginx"

  container_name = "hello-${random_pet.dog.id}"
  nginx_port = 8001
}
It also passes the random pet name to the hello module, which will generate outputs with the random pet name.

main.tf
module "hello" {
  source  = "joatmon08/hello/random"
  version = "6.0.0"

  hellos = {
    hello        = random_pet.dog.id
    second_hello = "World"
  }

  some_key = "NOTSECRET"
}
Initialize your configuration
In order to generate your execution plan, Terraform needs to install the providers and modules referenced by your configuration. Then, it will reference the locally cached providers and modules to create a plan of resource changes.

Initialize the Terraform configuration to install the required providers and modules.

 terraform init
Initializing modules...
Downloading registry.terraform.io/joatmon08/hello/random 6.0.0 for hello...
- hello in .terraform/modules/hello
- nginx-pet in nginx

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of kreuzwerker/docker from the dependency lock file
- Reusing previous version of hashicorp/random from the dependency lock file
- Installing kreuzwerker/docker v2.24.0...
- Installed kreuzwerker/docker v2.24.0 (self-signed, key ID BD080C4571C6104C)
- Installing hashicorp/random v3.4.3...
- Installed hashicorp/random v3.4.3 (signed by HashiCorp)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
Copy
Create a plan
There are three commands that tell Terraform to generate an execution plan:

The terraform plan command lets you to preview the actions Terraform would take to modify your infrastructure, or save a speculative plan which you can apply later. The function of terraform plan is speculative: you cannot apply it unless you save its contents and pass them to a terraform apply command. In an automated Terraform pipeline, applying a saved plan file ensures the changes are the ones expected and scoped by the execution plan, even if your pipeline runs across multiple machines.

The terraform apply command is the more common workflow outside of automation. If you do not pass a saved plan to the apply command, then it will perform all of the functions of plan and prompt you for approval before making the changes.

The terraform destroy command creates an execution plan to delete all of the resources managed in that project.

Generate a saved plan with the -out flag. You will review and apply this plan later in this tutorial.

 terraform plan -out tfplan

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

   docker_container.nginx will be created
  + resource "docker_container" "nginx" {

#...

Plan: 7 to add, 0 to change, 0 to destroy.

───────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
Copy
You can apply the saved plan file to execute these changes, but the contents are not in a human-readable format. Use the terraform show -json command to convert the plan contents into JSON, then pass it to jq to format it and save the output into a new file.

Warning

Terraform plan files can contain sensitive data. Never commit a plan file to version control, whether as a binary or in JSON format.

 terraform show -json tfplan | jq > tfplan.json
Copy
Review a plan
In order to determine the planned changes for your run, Terraform reconciles the prior state and the current configuration. In this section, you will review the data Terraform captures about your resources in a plan file.

At the top of the file, Terraform records the format version and Terraform version used to generate the plan. This will ensure that you use the same version to apply these changes if you used the saved plan.

 jq '.terraform_version, .format_version' tfplan.json
"1.3.6"
"1.1"
Copy
Review plan configuration
The .configuration object is a snapshot of your configuration at the time of the terraform plan.

This configuration snapshot captures the versions of the providers recorded in your .terraform.lock.hcl file, ensuring that you use the same provider versions that generated the plan to apply the proposed changes. Note that the configuration accounts for both the provider version used by the root module and child modules.

 jq '.configuration.provider_config' tfplan.json
{
  "docker": {
    "name": "docker",
    "full_name": "registry.terraform.io/kreuzwerker/docker",
    "version_constraint": "~> 2.24.0"
  },
  "random": {
    "name": "random",
    "full_name": "registry.terraform.io/hashicorp/random",
    "version_constraint": "~> 3.4.3"
  }
}
Copy
The configuration section further organizes your resources defined in your top level root_module.

 jq '.configuration.root_module.resources' tfplan.json
[
  {
    "address": "docker_container.nginx",
    "mode": "managed",
    "type": "docker_container",
    "name": "nginx",
    "provider_config_key": "docker",
    "expressions": {
      "image": {
        "references": [
          "docker_image.nginx.image_id",
          "docker_image.nginx"
        ]
      },
#...
Copy
The module_calls section contains the details of the modules used, their input variables and outputs, and the resources to create.

 jq '.configuration.root_module.module_calls' tfplan.json
{
  "hello": {
    "source": "joatmon08/hello/random",
    "expressions": {
      "hellos": {
        "references": [
          "random_pet.dog.id",
          "random_pet.dog"
        ]
      },
      "some_key": {
        "constant_value": "NOTSECRET"
      }
    },
#...
Copy
The configuration object also records any references to other resources in a resource's written configuration, which helps Terraform determine the correct order of operations.

 jq '.configuration.root_module.resources[0].expressions.image.references' tfplan.json
[
  "docker_image.nginx.image_id",
  "docker_image.nginx"
]
Copy
Review planned resource changes
Review the planned resources changes to the docker_image.nginx resource.

The representation includes:

The action field captures the action taken for this resource, in this case create.
The before field captures the resource state prior to the run. In this case, the value is null because the resource does not yet exist.
The after field captures the state to define for the resource.
The after_unknown field captures the list of values that will be computed or determined through the operation and sets them to true.
The before_sensitive and after_sensitive fields capture a list of any values marked sensitive. Terraform will use these lists to determine which output values to redact when you apply your configuration.
 jq '.resource_changes[] | select( .address == "docker_image.nginx")' tfplan.json
{
  "address": "docker_image.nginx",
  "mode": "managed",
  "type": "docker_image",
  "name": "nginx",
  "provider_name": "registry.terraform.io/kreuzwerker/docker",
  "change": {
    "actions": [
      "create"
    ],
    "before": null,
    "after": {
      "build": [],
      "force_remove": null,
      "keep_locally": false,
      "name": "nginx:latest",
      "pull_trigger": null,
      "pull_triggers": null,
      "triggers": null
    },
    "after_unknown": {
      "build": [],
      "id": true,
      "image_id": true,
      "latest": true,
      "output": true,
      "repo_digest": true
    },
    "before_sensitive": false,
    "after_sensitive": {
      "build": []
    }
  }
}
Copy
Review planned values
The planned_values object is another view of the differences between the "before" and "after" values of your resources, showing you the planned outcome for a run that would use this plan file.

In this example, the docker_image.nginx resource includes the address that you will use to reference the resource in your Terraform configuration, the provider name, and the values of all of the attributes as one object. This format resolves the differences between the prior and expected state in one object to demonstrate the planned outcomes for the configuration, which is easier to use for any downstream consumers of the plan data. For example, the Terraform Sentinel CLI tests policies against the planned outcomes recorded here. The cost estimation feature in Terraform Cloud also relies on the planned_values data to determine changes to your infrastructure spend.

 jq '.planned_values' tfplan.json
{
  "root_module": {
    "resources": [
     #...
        "address": "docker_image.nginx",
        "mode": "managed",
        "type": "docker_image",
        "name": "nginx",
        "provider_name": "registry.terraform.io/kreuzwerker/docker",
        "schema_version": 0,
        "values": {
          "build": [],
          "force_remove": null,
          "keep_locally": false,
          "name": "nginx:latest",
          "pull_trigger": null,
          "pull_triggers": null,
          "triggers": null
        },
        "sensitive_values": {
          "build": []
        }
      },
   #...
Copy
The planned_values object also lists the resources created by child modules in a separate list, and includes the address of the module.

 jq '.planned_values.root_module.child_modules' tfplan.json
[
  {
    "resources": [
      {
        "address": "module.hello.random_pet.number_2",
        "mode": "managed",
        "type": "random_pet",
        "name": "number_2",
        "provider_name": "registry.terraform.io/hashicorp/random",
        "schema_version": 0,
        "values": {
          "keepers": {
            "hello": "World"
          },
          "length": 2,
          "prefix": null,
          "separator": "-"
        },
        "sensitive_values": {
          "keepers": {}
        }
      },
#...
      }
    ],
    "address": "module.nginx-pet"
  }
]
Copy
Apply a saved plan
In your terminal, apply your saved plan.

Note

When you apply a saved plan file, Terraform will not prompt you for approval and instead immediately execute the changes, since this workflow is primarily used in automation.

 terraform apply tfplan
random_pet.dog: Creating...
random_pet.dog: Creation complete after 0s [id=singular-grouper]
docker_image.nginx: Creating...
module.nginx-pet.docker_image.nginx: Creating...
module.hello.random_pet.server: Creating...
module.hello.random_pet.number_2: Creating...
module.hello.random_pet.number_2: Creation complete after 0s [id=pumped-marten]
module.hello.random_pet.server: Creation complete after 0s [id=tidy-crawdad]
docker_image.nginx: Creation complete after 6s [id=sha256:1403e55ab369cd1c8039c34e6b4d47ca40bbde39c371254c7cba14756f472f52nginx:latest]
module.nginx-pet.docker_image.nginx: Creation complete after 6s [id=sha256:1403e55ab369cd1c8039c34e6b4d47ca40bbde39c371254c7cba14756f472f52nginx:latest]
docker_container.nginx: Creating...
module.nginx-pet.docker_container.nginx: Creating...
module.nginx-pet.docker_container.nginx: Creation complete after 0s [id=1d4430a5d214f637bedf42ee2d0131fceed9aa29b5b8c0377fd53176eeb54ac9]
docker_container.nginx: Creation complete after 1s [id=6eec4c1187d9c535d02c449d9d32e79022113e6caabea2de74e8aa3298b54344]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
Copy
Confirm that Terraform created the two containers.

 docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED              STATUS              PORTS                                                 NAMES
f61022b63ae4   c316d5a335a5           "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:8000->80/tcp                                  hello-terraform
595e01116168   c316d5a335a5           "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:8001->80/tcp                                  hello-positive-lion
Copy
Modify configuration
Input variables let you easily update configuration values without having to manually edit your configuration files.

Create a new variables.tf file in the top-level configuration directory. Add the configuration below to define a new input variable to use for the hello module.

variables.tf
Copy
variable "secret_key" {
  type        = string
  sensitive   = true
  description = "Secret key for hello module"
}
Then, create a terraform.tfvars file, and set the new secret_key input variable value.

terraform.tfvars
Copy
secret_key = "TOPSECRET"
Warning

Never commit .tfvars files to version control.

Finally, update the hello module configuration in main.tf to reference the new input variable.

main.tf
module "hello" {
  source  = "joatmon08/hello/random"
  version = "6.0.0"

  hellos = {
    hello        = random_pet.dog.id
    second_hello = "World"
  }

  some_key = var.secret_key
}
Create a new plan
Create a new Terraform plan and save it as tfplan-input-vars.

 terraform plan -out=tfplan-input-vars
random_pet.dog: Refreshing state... [id=singular-grouper]
docker_image.nginx: Refreshing state... [id=sha256:1403e55ab369cd1c8039c34e6b4d47ca40bbde39c371254c7cba14756f472f52nginx:latest]
module.nginx-pet.docker_image.nginx: Refreshing state... [id=sha256:1403e55ab369cd1c8039c34e6b4d47ca40bbde39c371254c7cba14756f472f52nginx:latest]
module.hello.random_pet.server: Refreshing state... [id=tidy-crawdad]
module.hello.random_pet.number_2: Refreshing state... [id=pumped-marten]
docker_container.nginx: Refreshing state... [id=6eec4c1187d9c535d02c449d9d32e79022113e6caabea2de74e8aa3298b54344]
module.nginx-pet.docker_container.nginx: Refreshing state... [id=1d4430a5d214f637bedf42ee2d0131fceed9aa29b5b8c0377fd53176eeb54ac9]

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

   module.hello.random_pet.server must be replaced
-/+ resource "random_pet" "server" {
      ~ id        = "tidy-crawdad" -> (known after apply)
      ~ keepers   = {  forces replacement
           Warning: this attribute value will be marked as sensitive and will not
           display in UI output after applying this change.
          ~ "secret_key" = (sensitive value)
             (1 unchanged element hidden)
        }
         (2 unchanged attributes hidden)
    }

Plan: 1 to add, 0 to change, 1 to destroy.

───────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan-input-vars

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan-input-vars"
Copy
Convert the new plan file into a machine-readable JSON format.

 terraform show -json tfplan-input-vars | jq > tfplan-input-vars.json
Copy
Review new plan
When you created this plan, Terraform determined that the working directory already contains a state file, and used that state to plan the resource changes.

Since Terraform created this plan with existing resources and using input variables, your plan file has some new fields.

Review plan input variables
Now that you have defined input variables, Terraform captures them in the plan file as well.

 jq '.variables' tfplan-input-vars.json
{
  "secret_key": {
    "value": "TOPSECRET"
  }
}
Copy
Warning

Although you marked the input variable as sensitive, Terraform still stores the value in plaintext in the plan file. Since Terraform plan files can contain sensitive information, you should keep them secure and never commit them to version control.

Unlike input variables, Terraform does not record the values of any environment variables used for your configuration in your plan files. Using environment variables is one of the recommended ways to pass sensitive values, such as provider credentials, to Terraform.

Review plan prior_state
When you created this plan, Terraform determined that the working directory already contains a state file, and used that state to plan the resource changes. Unlike the first run's plan file, this file now contains a prior_state object, which captures the state file exactly as it was prior to the plan action.

 jq '.prior_state' tfplan-input-vars.json
{
  "format_version": "1.0",
  "terraform_version": "1.3.6",
  "values": {
    "root_module": {
      "resources": [
        {
          "address": "docker_container.nginx",
          "mode": "managed",
          "type": "docker_container",
          "name": "nginx",
          "provider_name": "registry.terraform.io/kreuzwerker/docker",
          "schema_version": 2,
#...
Copy
Review resource drift
Terraform also accounts for the possibility that resources have changed outside of the Terraform workflow. As a result, the prior state may not reflect the actual attributes and settings of the resource at the time of the plan operation, which is known as state "drift". Terraform must reconcile these differences to understand which actions it must actually take to make your resources match the written configuration.

To determine whether state drift occurred, Terraform performs a refresh operation before it begins to build an execution plan. This refresh step pulls the actual state of all of the resources currently tracked in your state file. Terraform does not update your actual state file, but captures the refreshed state in the plan file.

In this case, Terraform noticed that the provider updated some attributes of the Docker containers and recorded the detected drift.

 jq '.resource_drift' tfplan-input-vars.json
[
  {
    "address": "docker_container.nginx",
    "mode": "managed",
    "type": "docker_container",
    "name": "nginx",
    "provider_name": "registry.terraform.io/kreuzwerker/docker",
    "change": {
      "actions": [
        "update"
      ],
      "before": {
        "attach": false,
        "bridge": "",
#...
        "after": {
          "attach": false,
          "bridge": "",
          "capabilities": [],
          "command": [
            "nginx",
            "-g",
            "daemon off;"
          ],
          "container_logs": null,
          "cpu_set": "",
          "cpu_shares": 0,
          "destroy_grace_seconds": null,
          "devices": [],
          "dns": [],
#...
Copy
Notice that the action listed is an update, which instructs Terraform to modify the state to reflect the detected state drift. Terraform uses this information to provide you with more detailed plan output and to accurately determine the necessary changes to your resources. However, Terraform will only apply changes to your state file during an apply step.

Review plan resource changes
Now that your state file tracks resources, Terraform will take the existing state into consideration when it creates an execution plan. For example, the module.hello.random_pet.server object now contains data in both the before and after fields, representing the prior and desired configurations respectively.

 jq '.resource_changes[] | select( .address == "module.hello.random_pet.server")' tfplan-input-vars.json
{
  "address": "module.hello.random_pet.server",
  "module_address": "module.hello",
  "mode": "managed",
  "type": "random_pet",
  "name": "server",
  "provider_name": "registry.terraform.io/hashicorp/random",
  "change": {
    "actions": [
      "delete",
      "create"
    ],
    "before": {
      "id": "tidy-crawdad",
  #...
    "after": {
      "keepers": {
        "hello": "fun-possum",
        "secret_key": "TOPSECRET"
      },
  #...
  "action_reason": "replace_because_cannot_update"
}
Copy
Notice that the actions list is now set to ["delete","create"] and that the action_reason is "replace_because_cannot_update" - the change to the secret_key for the resource is destructive, so Terraform must both delete and create this resource. Terraform determines whether it can update a resource in place or must recreate it based on which provider attributes you changed.

Once you have created resources in the working directory, Terraform uses the prior state, the data returned by a refresh operation, and the written configuration to determine the changes to make. Terraform supports additional flags that you can use to modify how it constructs an execution plan. For example, you can create a plan that only refreshes the state file without modifying resource configuration, or target only specific resources for either update or replacement.

Clean up infrastructure
Now that you have completed this tutorial, destroy the resources created before moving on. Confirm the operation with a yes.

 terraform destroy
#...
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

   docker_container.nginx will be destroyed
  - resource "docker_container" "nginx" {
#...
Plan: 0 to add, 0 to change, 7 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
#...
Destroy complete! Resources: 7 destroyed.
Copy
Next steps
In this tutorial, you reviewed how Terraform constructs an execution plan and uses saved plans. You also explored the relationship of the terraform plan and terraform apply commands.