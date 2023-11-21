
## Codespaces setup

```
code --install-extension HashiCorp.terraform
code --install-extension ms-azuretools.vscode-docker

docker run --rm -v /usr/local/bin:/target --entrypoint sh hashicorp/terraform -c 'cp /bin/terraform /target'
terraform -install-autocomplete
. ~/.profile
```

## Apply with vars
```
terraform apply \
  -var port=8001 \
  -var title="Lunchtime for lalyos" \
  -var color="yellow"
```

For engineers:
```
terraform apply \
  -auto-approve \
  -var port=8001 \
  -var title="Lunchtime for lalyos" \
  -var color="yellow"
```

## Terraform var from env
```
export TF_VAR_email=lalyos@lhs.de
```

## Terraform vars from file

create a file called: `terraform.tfvars`
```
email="lalyos@example.com"
port=8000
title="Lunchbreak soon ...."
color="hotpink"
```