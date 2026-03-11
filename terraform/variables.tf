# Configures workspace specific variables that can be overriden through specific configs from config/env.json.
# Variables are accessed like local.workspace["var"]
# Based on https://github.com/hashicorp/terraform/issues/15966#issuecomment-495818122
locals {
  default_settings = {
    region = "us-west-2"

    default_aws_tags = {
      ManagedBy = "terraform"
      Project = "localstack"
      Environment = "${terraform.workspace}"
    }

    environment_short = ""
  }

  tfsettingsfile = "config/${terraform.workspace}.json"
  tfsettingsfilecontent = fileexists(local.tfsettingsfile) ? file(local.tfsettingsfile) : "{}"
  tfenvsettings = jsondecode(local.tfsettingsfilecontent)
  workspace = merge(local.default_settings, local.tfenvsettings)
}
