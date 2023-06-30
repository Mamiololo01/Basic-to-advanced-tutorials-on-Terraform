# Apply Terraform Configuration

This repo is a companion repo to the [Apply Terraform Configuration tutorial](https://developer.hashicorp.com/terraform/tutorials/cli/apply).

The core Terraform workflow consists of three main steps once you have written your Terraform configuration:

Initialize prepares the working directory so Terraform can run the configuration.
Plan lets you preview any changes before you apply them.
Apply executes the changes defined by your Terraform configuration to create, update, or destroy resources.
When it makes changes to your infrastructure, Terraform uses the providers and modules installed during initialization to execute the steps stored in the execution plan. These steps create, update, and delete infrastructure to match your resource configuration.

In this tutorial, you will apply configuration to provision Docker containers on your local machine, and review the steps that Terraform takes to apply your configuration. You will also learn how Terraform recovers from errors during apply, and some common ways to use the apply command.

Prerequisites
The tutorial assumes that you are familiar with Terraform. If you are new to Terraform itself, refer first to the Get Started tutorials.

For this tutorial, you will need:

the Terraform 0.14+ CLI installed locally.
Docker.
jq.
Clone the example repository
In your terminal, clone the learn-terraform-apply repository.

 git clone https://github.com/hashicorp/learn-terraform-apply
Copy
Navigate to the cloned repository.

 cd learn-terraform-apply
Copy
Review configuration
Open the main.tf file. This file defines configuration for four Docker containers running the latest nginx image.

main.tf
provider "docker" {}

provider "random" {}

provider "time" {}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "random_pet" "nginx" {
  length = 2
}

resource "docker_container" "nginx" {
  count = 4
  image = docker_image.nginx.latest
  name  = "nginx-${random_pet.nginx.id}-${count.index}"

  ports {
    internal = 80
    external = 8000 + count.index
  }
}
In this example configuration, the docker_container.nginx resources depend on the random_pet.nginx and docker_image.nginx resources. When you apply this configuration, Terraform will create the image and random_pet resources first, followed by the containers.

Initialize configuration
Initialize your configuration to install the providers it references.

 terraform init
Copy
Apply configuration
When you apply this configuration, Terraform will:

Lock your project's state, so that no other instances of Terraform will attempt to modify your state or apply changes to your resources. If Terraform detects an existing lock file (.terraform.tfstate.lock.info), it will report an error and exit.
Create a plan, and wait for you to approve it. Alternatively, you can provide a saved speculative plan created with the terraform plan command, in which case Terraform will not prompt for approval.
Execute the steps defined in the plan using the providers you installed when you initialized your configuration. Terraform executes steps in parallel when possible, and sequentially when one resource depends on another.
Update your project's state file with a snapshot of the current state of your resources.
Unlock the state file.
Print out a report of the changes it made, as well as any output values defined in your configuration.
Apply the configuration.

 terraform apply
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

   docker_container.nginx[0] will be created
  + resource "docker_container" "nginx" {
      + attach           = false
      + bridge           = (known after apply)
#...
Plan: 6 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + nginx_hosts = [
      + {
          + host = "0.0.0.0:8000"
          + name = (known after apply)
        },
      + {
          + host = "0.0.0.0:8001"
          + name = (known after apply)
        },
      + {
          + host = "0.0.0.0:8002"
          + name = (known after apply)
        },
      + {
          + host = "0.0.0.0:8003"
          + name = (known after apply)
        },
    ]

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
Copy
Since you did not provide a saved speculative plan, Terraform created a plan and asked you to approve it before making any changes to your resources.

Respond to the confirmation prompt with a yes to apply the proposed execution plan.

#...

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
random_pet.nginx: Creating...
random_pet.nginx: Creation complete after 0s [id=renewed-quetzal]
docker_image.nginx: Creating...
docker_image.nginx: Creation complete after 0s [id=sha256:c316d5a335a5cf324b0dc83b3da82d7608724769f6454f6d9a621f3ec2534a5anginx:latest]
docker_container.nginx[1]: Creating...
docker_container.nginx[2]: Creating...
docker_container.nginx[3]: Creating...
docker_container.nginx[0]: Creating...
docker_container.nginx[1]: Creation complete after 0s [id=8a8eb6bb617b989810a0f5795466689f96d095700d765e09e44b5fcefa6756fa]
docker_container.nginx[2]: Creation complete after 0s [id=e061582c22a59c35239dd31a5cd0d016eb1e421f6b6bc5275d2985ec49ed3ba3]
docker_container.nginx[0]: Creation complete after 0s [id=70edfd0af1bec4c90140c206716eb7d790ef5b32669d1cafc90a23c52d7e947a]
docker_container.nginx[3]: Creation complete after 1s [id=af6778d36eec98916baf41c3b25c0b046564842fbcf46960cbf8fa24af6dc588]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

nginx_hosts = [
  {
    "host" = "0.0.0.0:8000"
    "name" = "nginx-renewed-quetzal-0"
  },
  {
    "host" = "0.0.0.0:8001"
    "name" = "nginx-renewed-quetzal-1"
  },
  {
    "host" = "0.0.0.0:8002"
    "name" = "nginx-renewed-quetzal-2"
  },
  {
    "host" = "0.0.0.0:8003"
    "name" = "nginx-renewed-quetzal-3"
  },
]
When you applied the example configuration, Terraform created the random pet name and image resources first, and then created the four containers which depend on them in parallel. When Terraform creates a plan, it analyzes the dependencies between your resources so that it makes changes to your resources in the correct order, and in parallel when possible.

Now that Terraform has provisioned your containers, use curl to send an HTTP request to one of them.

 curl $(terraform output -json nginx_hosts | jq -r '.[0].host')                     
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
Copy
The container will respond with the NGINX welcome page.

Errors during apply
When Terraform encounters an error during an apply step, it:

Logs the error and reports it to the console.
Updates the state file with any changes to your resources.
Unlocks the state file.
Exits.
Terraform does not support rolling back a partially-completed apply. Because of this, your infrastructure may be in an invalid state after a Terraform apply step errors out. After you resolve the error, you must apply your configuration again to update your infrastructure to the desired state.

To review how Terraform handles errors, introduce an intentional error during an apply.

Add the following configuration to main.tf to create a new Docker container running the latest Redis image.

main.tf
Copy
resource "docker_image" "redis" {
  name         = "redis:latest"
  keep_locally = true
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [docker_image.redis]

  create_duration = "60s"
}

resource "docker_container" "data" {
  depends_on = [time_sleep.wait_60_seconds]
  image      = docker_image.redis.latest
  name       = "data"

  ports {
    internal = 6379
    external = 6379
  }
}
The time_sleep.wait_after_image resource will introduce a 60 second delay between downloading the image and creating the container. During this time, you will remove the image from your local Docker instance in order to artificially introduce an error.

Tip

If you need more time, increase the value of the create_duration argument to the time_sleep.wait_after_image resource.

Apply the new configuration. Respond to the confirmation prompt with a yes.

 terraform apply
random_pet.nginx: Refreshing state... [id=renewed-quetzal]
docker_image.nginx: Refreshing state... [id=sha256:c316d5a335a5cf324b0dc83b3da82d7608724769f6454f6d9a621f3ec2534a5anginx:latest]
docker_container.nginx[1]: Refreshing state... [id=8a8eb6bb617b989810a0f5795466689f96d095700d765e09e44b5fcefa6756fa]
#...
   time_sleep.wait_60_seconds will be created
  + resource "time_sleep" "wait_60_seconds" {
      + create_duration = "60s"
      + id              = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

docker_image.redis: Creating...
docker_image.redis: Creation complete after 0s [id=sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19adredis:latest]
time_sleep.wait_60_seconds: Creating...
time_sleep.wait_60_seconds: Still creating... [10s elapsed]
Copy
After Terraform creates the Redis image resource, within 60 seconds, open a new terminal window and remove the image from your local Docker host.

 docker image rm redis:latest
Untagged: redis:latest
Untagged: redis@sha256:0d9c9aed1eb385336db0bc9b976b6b49774aee3d2b9c2788a0d0d9e239986cb3
Deleted: sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19ad
Deleted: sha256:5248e4fce7def91a350b6b4a6cb1123dab9c98075b44b6663c4994b4c680d23c
Deleted: sha256:555a11039e3c07f6ae3bc768248babe5db27eba042ed41cee9375c39a6e14bd4
Deleted: sha256:d59e9b328a1c924de9e59ea95b4c0dabf7b5f1ba834bb00f7cdfdf63020baba7
Deleted: sha256:ace8e13527f7c6e1e837e8235453a742e9675d28476a34f4639673bd89bb59d1
Deleted: sha256:f0083cf24bd0ba36ca8075baa8f2c9a46ffe382c9f865e5e245e682acfbe923c
Copy
Return to the terminal where terraform apply is running. Because you removed the image from Docker after Terraform provisioned it, Terraform will error out when it tries to create the docker_container.data container.

#...
time_sleep.wait_60_seconds: Still creating... [10s elapsed]
time_sleep.wait_60_seconds: Still creating... [20s elapsed]
time_sleep.wait_60_seconds: Still creating... [30s elapsed]
time_sleep.wait_60_seconds: Still creating... [40s elapsed]
time_sleep.wait_60_seconds: Still creating... [50s elapsed]
time_sleep.wait_60_seconds: Creation complete after 1m0s [id=2022-03-14T17:03:49Z]
docker_container.data: Creating...
╷
│ Error: Unable to create container with image sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19ad: unable to pull image sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19ad: error pulling image sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19ad: Error response from daemon: pull access denied for sha256, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
│ 
│   with docker_container.data,
│   on main.tf line 38, in resource "docker_container" "data":
│   38: resource "docker_container" "data" {
│ 
╵
Docker was unable to find the Redis image, so the Docker provider could not create the Redis container and reported the error to Terraform.

Common reasons for apply errors include:

A change to a resource outside of Terraform's control.
Networking or other transient errors.
An expected error from the upstream API, such as a duplicate resource name or reaching a resource limit.
An unexpected error from the upstream API, such as an internal server error.
A bug in the Terraform provider code, or Terraform itself.
Depending on the cause of the error, you may need to resolve the underlying issue by either modifying your configuration or diagnosing and resolving the error from the cloud provider API. In this example, Terraform successfully created the docker_image.redis resource, but was unable to create the containers because you made a change outside of Terraform's control by removing the image from Docker. Your Terraform project is still tracking the image resource because Terraform has not yet refreshed your resource's state.

Print out the state of your Terraform resources with terraform show.

 terraform show
 docker_container.nginx[0]:
resource "docker_container" "nginx" {
    attach            = false
    command           = [
        "nginx",
        "-g",
        "daemon off;",
    ]
#...

 docker_image.redis:
resource "docker_image" "redis" {
    id           = "sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19adredis:latest"
    keep_locally = true
    latest       = "sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19ad"
    name         = "redis:latest"
    repo_digest  = "redis@sha256:0d9c9aed1eb385336db0bc9b976b6b49774aee3d2b9c2788a0d0d9e239986cb3"
}

#...
Copy
The terraform show command prints out Terraform's current understanding of the state of your resources. It does not refresh your state, so the information in your state can be out of date. In this case, your project's state reports the existence of the Redis image you manually removed earlier in this tutorial.

The next time you plan a change to this project, Terraform will update the current state of your resources from the underlying APIs using the providers you have installed. Terraform will notice that the image represented by the docker_image.redis resource no longer exists. When you apply your configuration, Terraform will recreate the image resource before creating the docker_container.data container.

Apply your configuration. Respond to the confirmation prompt with a yes to provision the Redis image and container.

 terraform apply
random_pet.nginx: Refreshing state... [id=renewed-quetzal]
docker_image.nginx: Refreshing state... [id=sha256:c316d5a335a5cf324b0dc83b3da82d7608724769f6454f6d9a621f3ec2534a5anginx:latest]
docker_image.redis: Refreshing state... [id=sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19adredis:latest]
time_sleep.wait_60_seconds: Refreshing state... [id=2022-03-14T17:03:49Z]
docker_container.nginx[3]: Refreshing state... [id=af6778d36eec98916baf41c3b25c0b046564842fbcf46960cbf8fa24af6dc588]
docker_container.nginx[2]: Refreshing state... [id=e061582c22a59c35239dd31a5cd0d016eb1e421f6b6bc5275d2985ec49ed3ba3]
docker_container.nginx[1]: Refreshing state... [id=8a8eb6bb617b989810a0f5795466689f96d095700d765e09e44b5fcefa6756fa]
docker_container.nginx[0]: Refreshing state... [id=70edfd0af1bec4c90140c206716eb7d790ef5b32669d1cafc90a23c52d7e947a]

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply":

   docker_image.redis has been deleted
  - resource "docker_image" "redis" {
      - id           = "sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19adredis:latest" -> null
      - keep_locally = true -> null
      - latest       = "sha256:f1b6973564e91aecb808142499829a15798fdc783a30de902bb0c4133fee19ad" -> null
      - name         = "redis:latest" -> null
      - repo_digest  = "redis@sha256:0d9c9aed1eb385336db0bc9b976b6b49774aee3d2b9c2788a0d0d9e239986cb3" -> null
    }


Unless you have made equivalent changes to your configuration, or ignored the
relevant attributes using ignore_changes, the following plan may include
actions to undo or respond to these changes.

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

   docker_container.data will be created
  + resource "docker_container" "data" {
      + attach           = false
#...
    }

   docker_image.redis will be created
  + resource "docker_image" "redis" {
      + id           = (known after apply)
      + keep_locally = true
      + latest       = (known after apply)
      + name         = "redis:latest"
      + output       = (known after apply)
      + repo_digest  = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

docker_image.redis: Creating...
docker_image.redis: Creation complete after 6s [id=sha256:0e403e3816e890f6edc35de653396a5f379084e5ee6673a7608def32caec6c90redis:latest]
docker_container.data: Creating...
docker_container.data: Creation complete after 0s [id=ca47e22be5c1df303de7f2d27c31b1f91127a23d56e6f24c27fd17cd41769301]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

nginx_hosts = [
  {
    "host" = "0.0.0.0:8000"
    "name" = "nginx-renewed-quetzal-0"
  },
  {
    "host" = "0.0.0.0:8001"
    "name" = "nginx-renewed-quetzal-1"
  },
  {
    "host" = "0.0.0.0:8002"
    "name" = "nginx-renewed-quetzal-2"
  },
  {
    "host" = "0.0.0.0:8003"
    "name" = "nginx-renewed-quetzal-3"
  },
]
Copy
In this case, you were able to recover from the error by re-applying your configuration. Depending on the underlying cause of the error, you may need to resolve the error outside of Terraform or by changing your Terraform configuration. For example, if Terraform reports a resource limit error from your cloud provider, you may need to work with your cloud provider to increase that limit before applying your configuration.

Replace Resources
When using Terraform, you will usually apply an entire configuration change at once. Terraform and its providers will determine the changes to make and the order to make them in. However, there are some cases where you may need to replace or modify individual resources. Terraform provides two arguments to the apply command that allow you to interact with specific resources: -replace and -target.

Use the -replace argument when a resource has become unhealthy or stops working in ways that are outside of Terraform's control. For instance, a misconfiguration in your Docker container's OS configuration could require that the container be replaced. There is no corresponding change to your Terraform configuration, so you want to instruct Terraform to reprovision the resource using the same configuration.

The -replace argument requires a resource address. List the resources in your configuration with terraform state list.

 terraform state list
docker_container.data
docker_container.nginx[0]
docker_container.nginx[1]
docker_container.nginx[2]
docker_container.nginx[3]
docker_image.nginx
docker_image.redis
random_pet.nginx
time_sleep.wait_60_seconds
Copy
Replace the second Docker container. Respond to the confirmation prompt with a yes.

 terraform apply -replace "docker_container.nginx[1]"
docker_image.nginx: Refreshing state... [id=sha256:c316d5a335a5cf324b0dc83b3da82d7608724769f6454f6d9a621f3ec2534a5anginx:latest]
docker_image.redis: Refreshing state... [id=sha256:0e403e3816e890f6edc35de653396a5f379084e5ee6673a7608def32caec6c90redis:latest]
random_pet.nginx: Refreshing state... [id=renewed-quetzal]
#...
Terraform will perform the following actions:

   docker_container.nginx[1] will be replaced, as requested
-/+ resource "docker_container" "nginx" {
Plan: 1 to add, 0 to change, 1 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

docker_container.nginx[1]: Destroying... [id=07b8fc5f3212685b6b55178642b160157392ddb87b4ae683d628e9233aff8d4c]
docker_container.nginx[1]: Destruction complete after 0s
docker_container.nginx[1]: Creating...
docker_container.nginx[1]: Creation complete after 0s [id=c7e9a3a11b8a564211c95df91379d140ed71ad5389b948f7608ef4e2719b8470]

Apply complete! Resources: 1 added, 0 changed, 1 destroyed.

Outputs:

nginx_hosts = [
  {
    "host" = "0.0.0.0:8000"
    "name" = "nginx-renewed-quetzal-0"
  },
  {
    "host" = "0.0.0.0:8001"
    "name" = "nginx-renewed-quetzal-1"
  },
  {
    "host" = "0.0.0.0:8002"
    "name" = "nginx-renewed-quetzal-2"
  },
  {
    "host" = "0.0.0.0:8003"
    "name" = "nginx-renewed-quetzal-3"
  },
]
Copy
The second case where you may need to partially apply configuration is when troubleshooting an error that prevents Terraform from applying your entire configuration at once. This type of error may occur when a target API or Terraform provider error leaves your resources in an invalid state that Terraform cannot resolve automatically. Use the -target command line argument when you apply to target individual resources. Refer to the Target resources tutorial for more information.

Clean up infrastructure
Now that you have learned how Terraform applies changes to your infrastructure, remove the resources you provisioned in this tutorial. Confirm the operation with a yes.

