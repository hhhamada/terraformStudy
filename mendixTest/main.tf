variable "access_key" {}
variable "secret_key" {}
variable "region" {
    default = "ap-northeast-3"
}

provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

##################
#VPC
##################
resource "aws_vpc" "commonSaaSAP" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostname = true
    tags = {
        Name = "commonSaaSAP"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_vpc" "commonSaaSDB" {
    cidr_block = "10.1.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostname = false
    tags = {
        Name = "commonSaaSDB"
        Owner = "hamada"
        product = "mendixTest"
    }
}

##################
#public subnet
##################
resource "aws_subnet" "public_ap_a" {
    vpc_id = "${aws_vpc.commonSaaSAP.vpc_id}"
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "public_ap_a"
        Owner = "hamada"
        product = "mendixTest"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"
    }
}

resource "aws_subnet" "public_ap_b" {
    vpc_id = "${aws_vpc.commonSaaSAP.vpc_id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1b"
    tags = {
        Name = "public_ap_b"
        Owner = "hamada"
        product = "mendixTest"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"
    }
}

##################
#private subnet
##################
resource "aws_subnet" "private_ap_a" {
    vpc_id = "${aws_vpc.commonSaaSAP.vpc_id}"
    cidr_block = "10.0.32.0/24"
    map_public_ip_on_launch = false
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "private_ap_a"
        Owner = "hamada"
        product = "mendixTest"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_subnet" "private_ap_b"{
    vpc_id = "${aws_vpc.commonSaaSAP.vpc_id}"
    cidr_block = "10.0.33.0/24"
    map_public_ip_on_launch = false
    availability_zone = "ap-northeast-1b"
    tags = {
        Name = "private_ap_b"
        Owner = "hamada"
        product = "mendixTest"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_subnet" "private_db_a"{
    vpc_id = "${aws_vpc.commonSaaSDB.vpc_id}"
    cidr_block = "10.1.32.0/24"
    map_public_ip_on_launch = false
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "private_db_a"
        Owner = "hamada"
        product = "mendixTest"
    }
}

##################
#IGW
##################
resource "aws_internet_gateway" "commonSaaSAPGW" {
    vpc_id = "${aws_vpc.commonSaaSAP.id}"
    depends_on = "${aws_vpc.commonSaaSAP}"
    tags = {
        Name = "commonSaaSAPGW"
        Owner = "hamada"
        product = "mendixTest"
    }
}

##################
#eip
##################
resource "aws_eip" "for_nat_gateway1" {
    vpc = true
    tags = {
        Name = "fpr_nat_gateway1"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_eip" "for_nat_gateway2" {
    vpc = true
    tags = {
        Name = "for_nat_gateway2"
        Owner = "hamada"
        product = "mendixTest"
    }
}

##################
#nat gateway
##################
resource "aws_nat_gateway" "for_eks_fargate1" {
    depends_on = ["${aws_internet_gateway.commonSaaSAPGW}"]
    subnet_id = "${aws_subnet.public_ap_a}"
    allocation_id = "${aws_eip.for_nat_gateway1}"
    tags = {
        Name = "for_eks_fargate1"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_nat_gateway" "for_eks_fargate2" {
    depends_on = ["${aws_internet_gateway.commonSaaSAPGW}"]
    subnet_id = "${aws_subnet.public_ap_b}"
    allocation_id = "${aws_eip.for_nat_gateway2}"
    tags = {
        Name = "for_eks_fargate1"
        Owner = "hamada"
        product = "mendixTest"
    }
}

##################
#route_table
##################
resource "aws_route_table" "public_rt" {
    vpc_id = "${aws_vpc.commonSaaSAP.id}"
    tags = {
        name = "public_route"
        Owner = "hamada"
        product = "mendixTest"
    }
}

resource "aws_route" "public_route" {
    route_table_id = "${aws_route_table.public_rt.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.commonSaaSAPGW.id}"
}

resource "aws_route_table_association" "public_a_assoc"{
    subnet_id = "${aws_subnet.public_a.id}"
    route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_route_table_association" "public_b_assoc"{
    subnet_id = "${aws_subnet.public_b.id}"
    route_table_id = "${aws_route_table.public_rt.id}"
}




resource "aws_route_table" "private_rt" {
    vpc_id = "${aws_vpc.commonSaaSAP.id}"
    tags = {
        name = "private_rt"
        Owner = "hamada"
        product = "mendixTest"
        
    }
}

resource "aws_route" "private_route"{
    
}

resource "aws_route_table_association" "private_a_assoc"{
    subnet_id = "${aws_subnet.private_a.id}"
    route_table_id = "${aws_route_table.private_rt.id}"
}

resource "aws_security_group" "admin"{

}