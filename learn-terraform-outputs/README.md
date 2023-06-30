# Learn Terraform outputs

This repo is a companion repo to the [Learn Terraform outputs](https://developer.hashicorp.com/terraform/tutorials/configuration-language/outputs) tutorial.
It contains Terraform configuration you can use to learn how Terraform output values allow you to export structured data about your resources.

Terraform output values let you export structured data about your resources. You can use this data to configure other parts of your infrastructure with automation tools, or as a data source for another Terraform workspace. Outputs are also how you expose data from a child module to a root module.

In this tutorial, you will use Terraform to deploy application infrastructure on AWS and use outputs to get information about the resources. Then, you will use the sensitive flag to reduce the risk of inadvertently disclosing the database administrator username and password. You will also learn how to format outputs into machine-readable JSON.

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
Clone the example repository for this tutorial, which contains Terraform configuration for a web application including a VPC, load balancer, EC2 instances, and a database.

 git clone https://github.com/hashicorp/learn-terraform-outputs.git
Copy
Change to the repository directory.

 cd learn-terraform-outputs
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
Now apply the configuration. Respond yes to the prompt to confirm the operation.

 terraform apply
#...
Plan: 46 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

  Enter a value: yes
#...

Apply complete! Resources: 46 added, 0 changed, 0 destroyed.
Copy
Output VPC and load balancer information
You can add output declarations anywhere in your Terraform configuration files. However, we recommend defining them in a separate file called outputs.tf to make it easier for users to understand your configuration and review its expected outputs.

Add a block to outputs.tf to show the ID of the VPC.

outputs.tf
Copy
output "vpc_id" {
  description = "ID of project VPC"
  value       = module.vpc.vpc_id
}
While the description argument is optional, you should include it in all output declarations to document the intent and content of the output.

You can use the result of any Terraform expression as the value of an output. Add the following definitions to outputs.tf.

outputs.tf
Copy
output "lb_url" {
  description = "URL of load balancer"
  value       = "http://${module.elb_http.elb_dns_name}/"
}

output "web_server_count" {
  description = "Number of web servers provisioned"
  value       = length(module.ec2_instances.instance_ids)
}
The lb_url output uses string interpolation to create a URL from the load balancer's domain name. The web_server_count output uses the length() function to calculate the number of instances attached to the load balancer.

Terraform stores output values in the configuration's state file. In order to see these outputs, you need to update the state by applying this new configuration, even though the infrastructure will not change. Respond to the confirmation prompt with a yes.

 terraform apply
random_string.lb_id: Refreshing state... [id=5YI]
module.vpc.aws_vpc.this[0]: Refreshing state... [id=vpc-004c2d1ba7394b3d6]

# ...

Plan: 0 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + lb_url           = "http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/"
  + vpc_id           = "vpc-004c2d1ba7394b3d6"
  + web_server_count = 4

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes


Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

lb_url = "http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/"
vpc_id = "vpc-004c2d1ba7394b3d6"
web_server_count = 4
Copy
Query outputs
After creating the outputs, use the terraform output command to query all of them.

 terraform output
lb_url = "http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/"
vpc_id = "vpc-004c2d1ba7394b3d6"
web_server_count = 4
Copy
Next, query an individual output by name.

 terraform output lb_url
"http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/"
Copy
Starting with version 0.14, Terraform wraps string outputs in quotes by default. You can use the -raw flag when querying a specified output for machine-readable format.

 terraform output -raw lb_url
http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/
Copy
Use the lb_url output value with the -raw flag to cURL the load balancer and verify the response.

 curl $(terraform output -raw lb_url)
<html><body><div>Hello, world!</div></body></html>
Copy
If you are using Terraform Cloud, you can also find a table of your configuration's outputs on your workspace's overview page.

Redact sensitive outputs
You can designate Terraform outputs as sensitive. Terraform will redact the values of sensitive outputs to avoid accidentally printing them out to the console. Use sensitive outputs to share sensitive data from your configuration with other Terraform modules, automation tools, or Terraform Cloud workspaces.

Terraform will redact sensitive outputs when planning, applying, or destroying your configuration, or when you query all of your outputs. Terraform will not redact sensitive outputs in other cases, such as when you query a specific output by name, query all of your outputs in JSON format, or when you use outputs from a child module in your root module.

Add the following output blocks to your outputs.tf file. Note that the sensitive attribute is set to true.

outputs.tf
Copy
output "db_username" {
  description = "Database administrator username"
  value       = aws_db_instance.database.username
  sensitive   = true
}

output "db_password" {
  description = "Database administrator password"
  value       = aws_db_instance.database.password
  sensitive   = true
}
Apply this change to add these outputs to your state file, and respond to the confirmation prompt with yes.

 terraform apply
random_string.lb_id: Refreshing state... [id=5YI]
module.vpc.aws_vpc.this[0]: Refreshing state... [id=vpc-004c2d1ba7394b3d6]

# ...

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

db_password = <sensitive>
db_username = <sensitive>
lb_url = "http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/"
vpc_id = "vpc-004c2d1ba7394b3d6"
web_server_count = 4
Copy
Notice that Terraform redacts the values of the outputs marked as sensitive.

Use terraform output to query the database password by name, and notice that Terraform will not redact the value when you specify the output by name.

 terraform output db_password
"notasecurepassword"
Copy
Terraform stores all output values, including those marked as sensitive, as plain text in your state file.


Terraform OSS

Terraform Cloud
Use the grep command to see the values of the sensitive outputs in your state file.

 grep --after-context=10 outputs terraform.tfstate
  "outputs": {
    "db_password": {
      "value": "notasecurepassword",
      "type": "string",
      "sensitive": true
    },
    "db_username": {
      "value": "admin",
      "type": "string",
      "sensitive": true
    },
Copy
The sensitive argument for outputs can help avoid inadvertent exposure of those values. However, you must still keep your Terraform state secure to avoid exposing these values.

Generate machine-readable output
The Terraform CLI output is designed to be parsed by humans. To get machine-readable format for automation, use the -json flag for JSON-formatted output.

 terraform output -json
{
  "db_password": {
    "sensitive": true,
    "type": "string",
    "value": "notasecurepassword"
  },
  "db_username": {
    "sensitive": true,
    "type": "string",
    "value": "admin"
  },
  "lb_url": {
    "sensitive": false,
    "type": "string",
    "value": "http://lb-5YI-project-alpha-dev-2144336064.us-east-1.elb.amazonaws.com/"
  },
  "vpc_id": {
    "sensitive": false,
    "type": "string",
    "value": "vpc-004c2d1ba7394b3d6"
  },
  "web_server_count": {
    "sensitive": false,
    "type": "number",
    "value": 4
  }
}
Copy
Terraform does not redact sensitive output values with the -json option, because it assumes that an automation tool will use the output.

Clean up your infrastructure
Before moving on, destroy the infrastructure you created in this tutorial to avoid incurring unnecessary costs. Be sure to respond to the confirmation prompt with yes.

 terraform destroy
#...
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
#...
Apply complete! Resources: 0 added, 0 changed, 46 destroyed.
Copy
If you used Terraform Cloud for this tutorial, after destroying your resources, delete the learn-terraform-outputs workspace from your Terraform Cloud organization.



