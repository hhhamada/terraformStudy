module "example_sg" {
    source      = "./security_group"
    name        = "module_sg"
    vpc_id      = aws_vpc.example.id
    port        = 80
    cidr_blocks = ["0.0.0.0/0"]
}

module "http_sg" {
    source      = "./security_group"
    name        = "http-sg"
    vpc_id      = "aws_vpc.example.id"
    port        = 80
    cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
    source      = "./security_group"
    name        = "https-sg"
    vpc_id      = "aws_vpc.example.id"
    port        = 443
    cidr_blocks = ["0.0.0.0/0"]
}
    
module "http_redirect_sg" {
    source      = "./security_group"
    name        = "https-sg"
    vpc_id      = "aws_vpc.example.id"
    port        = 8080
    cidr_blocks = ["0.0.0.0/0"]
}