
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

## escaping vars with here-doc
```
body=<<KRUMPLI
<iframe src="https://giphy.com/embed/FR61sPFtyp5MnifIN0" width="480" height="480" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/studiocwf-cat-ciri-whitecat-FR61sPFtyp5MnifIN0">via GIPHY</a></p>
KRUMPLI
```

## Output

Use output in script
```
curl $(terraform output -raw url)
```