module "web_server" {
    source        = "./http_server"
    instance_type = "t3.micro"
}


output "example_public_dns" {
    value = module.web_server.public_dns
}