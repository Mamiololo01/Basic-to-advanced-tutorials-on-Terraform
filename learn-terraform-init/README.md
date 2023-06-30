# Initialize a Terraform Working Directory

This is a companion repository to the ["Initialize a Terraform Working Directory"](https://developer.hashicorp.com/terraform/tutorials/cli/init) tutorial.

This directory contains configuration that uses multiple providers, a local module, and a remote module. You will use these resources to review how Terraform initializes the working directory.

Here, you will find the following files:

the versions.tf file defines the terraform block. In it, the required_providers block specifies the provider and provider version required by the configuration.

the main.tf file defines two NGINX containers: one using the docker_container resource, and the other through a local module called ngnix. The configuration also includes the hello module, a public module that returns a random pet name.

the nginx directory contains a Terraform module that defines an NGINX container. It accepts the container_name and nginx_port inputs, which configure the container's name and external port number respectively.

Initialize your configuration
Initialize the Terraform configuration.

 terraform init
Copy
The output describes the steps Terraform executes when you initialize your configuration.

Terraform downloads the modules referenced in the configuration. It determines that the hello module is a remote module, so it downloads it from the public Terraform Registry. It also recognizes that the module "nginx-pet" block uses the local nginx module.

When you change a module's source or version, you must re-initialize your Terraform configuration or run terraform get to download the new version or from a different source.

Terraform initializes the backend. Since the terraform block does not include a cloud or backend block, Terraform defaults to the local backend.

Initializing the backend...
If the cloud block is present when you initialize the working directory, Terraform will integrate with Terraform Cloud and create a Terraform Cloud workspace with the name specified in the block if it does not yet exist.

Note

When you change a configuration's backend, you must re-initialize your Terraform configuration.

Terraform downloads the providers referenced in the configuration. Since the configuration does not yet have a lock file, Terraform downloads the docker and random providers as specified in versions.tf.

By default, Terraform will attempt to download the provider version specified by the lock file (.terraform.lock.hcl). If the lock file does not exist, Terraform will use the required_providers block to determine the provider version. If neither exists, Terraform will download the latest provider version.

Terraform creates a lock file, which records the versions and hashes of the providers used in this run. This ensures consistent Terraform runs in different environments, since Terraform will download the versions recorded in the lock file for future runs by default.

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.
You only need to initialize configuration the first time you use it or if you modify any provider version, module version, or backend. You will do this in the Reinitialize configuration section.

Now that you have installed the providers and modules used by the configuration, Terraform can verify whether your configuration syntax is valid and internally consistent. This includes checking if your resources are missing required fields or have mismatched argument types. You must initialize in order to validate your configuration.

Validate your configuration.

 terraform validate
Success! The configuration is valid.
Copy
Review initialization artifacts
When Terraform initializes a new Terraform directory, it creates a lock file named .terraform.lock.hcl and the .terraform directory.

Explore lock file
The lock file ensures that Terraform uses the same provider versions across your team and in ephemeral remote execution environments. During initialization, Terraform will download the provider versions specified by this file rather than the latest versions.

Open .terraform.lock.hcl to review its structure and contents.

.terraform.lock.hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.


If the versions defined in the lock file provider block conflict with the versions defined in the versions.tf file's required_providers block, Terraform will prompt you to re-initialize your configuration using the -upgrade flag. You will do this in the Update provider and module versions section.

Explore the .terraform directory
Terraform uses the .terraform directory to store the project's providers and modules. Terraform will refer to these components when you run validate, plan, and apply,

Note

Terraform automatically manages .terraform. Do not directly modify this directory's contents. Exploring the .terraform directory is meant to deepen your understanding of how Terraform works, but the contents and structure of this directory are subject to change between Terraform versions.

View the .terraform directory structure.

 tree .terraform -L 1
.terraform
├── modules
└── providers
Notice that the .terraform directory contains two sub-directories: modules and providers.

The .terraform/modules directory contains a modules.json file and local copies of remote modules.

 tree .terraform/modules
├── hello
│   ├── README.md
│   └── random.tf
└── modules.json
Open modules.json. This file shows that the configuration uses three modules: the root module, the remote hello module, and the local nginx-pet module.


Since the hello module is remote, Terraform downloaded the module from its source and saved a local copy in the .terraform/modules/hello directory during initialization. Open the files in .terraform/modules/hello to view the module's configuration. These files are intended to be read-only. Like the other contents in .terraform, do not modify them. Terraform will only update a remote module when you run terraform init -upgrade.

Since the nginx-pet module refers to a local module, Terraform refers directly to the module configuration. This means that if you make changes to a local module, Terraform will recognize them immediately.

The .terraform/providers directory stores cached versions of all of the configuration's providers.

View the .terraform/providers directory. When you ran terraform init earlier, Terraform downloaded the providers defined in your configuration from the provider's source (defined by the required_providers block) and saved them in their respective directories, defined as [hostname]/[namespace]/[name]/[version]/[os_arch].

 tree .terraform/providers
.terraform/providers
└── registry.terraform.io
    ├── hashicorp
    │   └── random
    │       └── 3.1.0
    │           └── darwin_amd64
    │               └── terraform-provider-random_v3.1.0_x5
    └── kreuzwerker
        └── docker
            └── 2.16.0
                └── darwin_amd64
                    ├── CHANGELOG.md
                    ├── LICENSE
                    ├── README.md
                    └── terraform-provider-docker_v2.16.0


Since you updated the provider and module versions, you must re-initialize the configuration for Terraform to install the updated versions.

If you attempt to validate, plan, or apply your configuration before doing so, Terraform will prompt you to re-initialize.

 terraform validate
╷
│ Error: Module version requirements have changed
│ 
│   on main.tf line 30, in module "hello":
│   30:   source  = "joatmon08/hello/random"
│ 
│ The version requirements have changed since this module was 
│ installed and the installed version (3.0.1) is no longer acceptable. 
│ Run "terraform init" to install all modules required by this configuration.
╵ 
Copy
Re-initialize your configuration.

 terraform init
Initializing modules...
Downloading registry.terraform.io/joatmon08/hello/random 3.1.0 for hello...
- hello in .terraform/modules/hello

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/random from the dependency lock file
- Reusing previous version of kreuzwerker/docker from the dependency lock file
- Using previously-installed kreuzwerker/docker v2.16.0
╷
│ Error: Failed to query available provider packages
│ 
│ Could not retrieve the list of available versions for provider 
│ hashicorp/random: locked provider registry.terraform.io/hashicorp/random
│ 3.1.0 does not match configured version constraint 3.0.1; must 
│ use terraform init -upgrade to allow selection of new versions
╵
Copy
Notice that Terraform downloaded the updated module version and saved it in .terraform/modules/hello. However, Terraform was unable to update the provider version since the new provider version conflicts with the version found in the lock file.

Re-initialize your configuration with the -upgrade flag. This tells Terraform to download the new version of the provider, and update the version and signature in the lock file.


Terraform has made some changes to the provider dependency selections recorded
in the .terraform.lock.hcl file. Review those changes and commit them to your
version control system if they represent changes you intended to make.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
Copy
View the .terraform/providers directory structure. Notice that Terraform installed the updated random provider version.

 tree .terraform/providers -L 4
.terraform/providers
└── registry.terraform.io
    ├── hashicorp
    │   └── random
    │       ├── 3.0.1
    │       └── 3.1.0
    └── kreuzwerker
        └── docker
            └── 2.16.0
Copy
Open the lock file. Notice that the random provider now uses version 3.0.1. Even though there are two versions of the random provider in .terraform/providers, Terraform will always use the version recorded in the lock file.

.terraform.lock.hcl
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/random" {
  version     = "3.0.1"
  constraints = "3.0.1"
  hashes = [
    "h1:0QaSbRBgBi8vI/8IRwec1INdOqBxXbgsSFElx1O4k4g=",
    ## ...
    "zh:e385e00e7425dda9d30b74ab4ffa4636f4b8eb23918c0b763f0ffab84ece0c5c",
  ]
}
Reconcile configuration
Since you have updated your provider and module version, check whether your configuration is still valid.

 terraform validate
╷
│ Error: Missing required argument
│ 
│   on main.tf line 29, in module "hello":
│   29: module "hello" {
│ 
│ The argument "second_hello" is required, but no definition was found.
╵
Copy
The new version of the hello module expects a new required argument. Add the second_hello required argument to the hello module.

iguration is valid.
Copy
Now your Terraform project is initialized and ready to be applied.
