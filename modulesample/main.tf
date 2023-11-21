module "webserver" {
  source = "github.com/lalyos/azure-web-module"
    unumber = "u9999999"
    location = "westeurope"
    body = "Hello from Terraform"
    title = "Welcome to Terraform"
    color = "lightblue"
    owner = "jeno@example.com"
    costcenter = "99999"
    packages = ["nginx", "git"]
}

output "publicip" {
  value = module.webserver.publicip
}