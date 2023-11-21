module "webserver" {
  source     = "github.com/lalyos/terralufi.git//azure"
  unumber    = "u9999999"
  location   = "westeurope"
  body       = <<-EOF
    <iframe src="https://giphy.com/embed/xk5jrZNNQjNF6fxRig" width="480" height="388" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/film-magyar-rgi-xk5jrZNNQjNF6fxRig">via GIPHY</a></p>
  EOF
  title      = "The End"
  color      = "mediumpurple"
  owner      = "jeno@example.com"
  costcenter = "99999"
  packages   = ["nginx", "git"]
}

output "publicip" {
  value = module.webserver.publicip
}
