# Python Lambda Template

This repository contains terraform which can be used to wrap python code with its dependencies for deployment in AWS as a lambda function.

It uses 2 scripts to wrap the dependencies with the code, and then cleanup upon deployment.

The terraform is written with CI/CD in mind. Edit the python as you wish and simply rerun the `terraform apply` command to recreate the lambda function.

A very simple IAM role is included for the function.

 ---

## Setup

Install [Terraform](https://www.terraform.io/).

Install the version of python you intend to use as the lambda runtime... e.g `python3.8`.

Export your AWS credentials as environment variables. As I'm using ubuntu, I've added mine to my `~/.bashrc`.
```
export AWS_ACCESS_KEY_ID="<ACCESS KEY>"
export AWS_SECRET_ACCESS_KEY="<SECRET KEY>"
```

Setup a directory for the source code of your lambda, and at the same level download or clone this directory. You may wish to rename it 'terraform', e.g.
```
- src
    - __init__.py
    - <LAMBDA_CODE>.py
    - requirements.txt
- terraform
    - main.tf
    - variables.tf
    - terraform.tfvars
```
> Note: `__init__.py` is an empty file. If not using extra libraries, a `requirements.txt` is not required. The dir for the lambda source code need not be named `src`. Simply adjust in the tfvars file.

Edit the `terraform.tfvars` so that the variable values make sense. Descriptions for the variables can be found in `variables.tf`.

> Note: Where I use this repo as a submodule, I create a branch for any changes I make specific to be used for the parent repo. Any changes I make to master may then get merged into the branches, but the branches won't get merged into master!

---

## Deployment

From inside the terraform directory run the following commands to deploy the code:

```
terraform init
terraform apply
# When prompted, type 'yes' and hit enter
```
This should create a lambda within AWS. Go look!
