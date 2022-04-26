variable "access_key" {}
variable "secret_key {}
variable "region" {
    default = "ap-northeast-3"
}

provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

resource "aws_vpc" "commonSaaSAP" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostname = "false"
    tags = {
        Name = "commonSaaSAP"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource aws_vpc "commonSaaSDB" {
    cidr_block = "10.1.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostname = "false"
    tags = {
        Name = "commonSaaSDB"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_internet_gateway" "commonSaaSAPGW" {
    vpc_id = "${aws_vpc.commonSaaSAP.id}"
    depends_on = "${aws_vpc.myVPC}"
    tags = {
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_subnet" "public_AP_a" {
    vpc_id = "${aws_vpc.commonSaaSAP.vpc_id}
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "public_AP_a"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_subnet" "public_AP_b" {
    vpc_id = "${aws_vpc.commonSaaSAP.vpc_id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1b"
    tags = {
        Name = "public_AP_b"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_subnet" "private_AP_a"{
    vpc_id = "${aws_vpc.commonSaaSAP.vpc_id}
    cidr_block = "10.0.32.0/24"
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "private_AP_a"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_subnet" "private_AP_b"{
    vpc_id = "${aws_vpc.commonSaaSAP.vpc_id}
    cidr_block = "10.0.33.0/24"
    availability_zone = "ap-northeast-1b"
    tags = {
        Name = "private_AP_b"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_subnet" "private_DB_a"{
    vpc_id = "${aws_vpc.commonSaaSDB.vpc_id}
    cidr_block = "10.1.32.0/24"
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "private_DB_a"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_route_table" "public_route" {
    vpc_id = "${aws_vpc.commonSaaSAP.id}"
    tags = {
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_route_table" "private_route" {
    vpc_id = "${aws_vpc.commonSaaSDB.id}"
    tags = {
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_route_table_association" "public_a_assoc"{
    subnet_id = "${aws_subnet.public_a.id}"
    route_table_id = "${aws_route_table.public_route.id}
}

resource "aws_route_table_association" "public_b_assoc"{
    subnet_id = "${aws_subnet.public_b.id}"
    route_table_id = "${aws_route_table.public_route.id}
}

resource "aws_route_table_association" "private_a_assoc"{
    subnet_id = "${aws_subnet.private_a.id}"
    route_table_id = "${aws_route_table.private_route.id}
}

resource "aws_route" "commonSaaS_igw" {
    route_table_id = "${aws_route_table.public_route.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.commonSaaSAPGW.id}"
    depends_on = ["${aws_route_table.public_route}"]
}

resource "aws_security_group" "admin"{

}