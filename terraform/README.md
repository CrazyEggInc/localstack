# Terraform

## Getting Started

Install Terraform https://learn.hashicorp.com/terraform/getting-started/install.html

Then, from the project root:

```
cd terraform
terraform init
terraform show
```

The default terraform workspace is `default`. For deployments we have `staging` (`us-west-2`) and `production` (`us-east-1`). To change workspaces:

```
terraform workspace select production
```
