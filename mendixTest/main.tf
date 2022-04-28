variable "access_key" {}
variable "secret_key" {}
variable "region" {
    default = "ap-northeast-3"
}

provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region = var.region
}

locals {
    eks_cluster_name = "mendix_cluster"
    eks_fargate_kubesystem_profaile_name = "kubesystem"
    eksalbingresscontroller_policy_name = "ingress_policy"
    ekspodexecution_role_name = "podexerole"
}

##################
#VPC
##################
resource "aws_vpc" "commonSaaSAP" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "commonSaaSAP"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        Owner = "hamada"
        Product = "mendixTest"
    }
}

resource "aws_vpc" "commonSaaSDB" {
    cidr_block = "10.1.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = false
    tags = {
        Name = "commonSaaSDB"
        Owner = "hamada"
        Product = "mendixTest"
    }
}

##################
#public subnet
##################
resource "aws_subnet" "public_ap_a" {
    vpc_id = aws_vpc.commonSaaSAP.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "public_ap_a"
        Owner = "hamada"
        Product = "mendixTest"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"
    }
}

resource "aws_subnet" "public_ap_b" {
    vpc_id = aws_vpc.commonSaaSAP.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1b"
    tags = {
        Name = "public_ap_b"
        Owner = "hamada"
        Product = "mendixTest"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"
    }
}

##################
#private subnet
##################
resource "aws_subnet" "private_ap_a" {
    vpc_id = aws_vpc.commonSaaSAP.id
    cidr_block = "10.0.32.0/24"
    map_public_ip_on_launch = false
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "private_ap_a"
        Owner = "hamada"
        Product = "mendixTest"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_subnet" "private_ap_b"{
    vpc_id = aws_vpc.commonSaaSAP.id
    cidr_block = "10.0.33.0/24"
    map_public_ip_on_launch = false
    availability_zone = "ap-northeast-1b"
    tags = {
        Name = "private_ap_b"
        Owner = "hamada"
        Product = "mendixTest"
        "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

resource "aws_subnet" "private_db_a"{
    vpc_id = aws_vpc.commonSaaSDB.id
    cidr_block = "10.1.32.0/24"
    map_public_ip_on_launch = false
    availability_zone = "ap-northeast-1a"
    tags = {
        Name = "private_db_a"
        Owner = "hamada"
        Product = "mendixTest"
    }
}

##################
#IGW
##################
resource "aws_internet_gateway" "commonSaaSAPGW" {
    vpc_id = aws_vpc.commonSaaSAP.id
    depends_on = [aws_vpc.commonSaaSAP]
    tags = {
        Name = "commonSaaSAPGW"
        Owner = "hamada"
        Product = "mendixTest"
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
        Product = "mendixTest"
    }
}

resource "aws_eip" "for_nat_gateway2" {
    vpc = true
    tags = {
        Name = "for_nat_gateway2"
        Owner = "hamada"
        Product = "mendixTest"
    }
}

##################
#nat gateway
##################
resource "aws_nat_gateway" "for_eks_fargate1" {
    depends_on = [aws_internet_gateway.commonSaaSAPGW]
    subnet_id = aws_subnet.public_ap_a.id
    allocation_id = aws_eip.for_nat_gateway1.id
    tags = {
        Name = "for_eks_fargate1"
        Owner = "hamada"
        Product = "mendixTest"
    }
}

resource "aws_nat_gateway" "for_eks_fargate2" {
    depends_on = [aws_internet_gateway.commonSaaSAPGW]
    subnet_id = aws_subnet.public_ap_b.id
    allocation_id = aws_eip.for_nat_gateway2.id
    tags = {
        Name = "for_eks_fargate1"
        Owner = "hamada"
        Product = "mendixTest"
    }
}

##################
#public route_table
##################
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.commonSaaSAP.id
    tags = {
        Name = "public_route"
        Owner = "hamada"
        Product = "mendixTest"
    }
}

resource "aws_route" "public_route" {
    route_table_id = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.commonSaaSAPGW.id
}

resource "aws_route_table_association" "public_a_assoc"{
    subnet_id = aws_subnet.public_ap_a.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc"{
    subnet_id = aws_subnet.public_ap_b.id
    route_table_id = aws_route_table.public_rt.id
}

##################
#private route table
##################
resource "aws_route_table" "private_rt1" {
    vpc_id = aws_vpc.commonSaaSAP.id
    tags = {
        Name = "private_rt"
        Owner = "hamada"
        Product = "mendixTest"
        
    }
}

resource "aws_route" "private_route1" {
    route_table_id = aws_route_table.private_rt1.id
    nat_gateway_id = aws_nat_gateway.for_eks_fargate1.id
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_a_assoc" {
    subnet_id = aws_subnet.private_ap_a.id
    route_table_id = aws_route_table.private_rt1.id
}

resource "aws_route_table" "private_rt2" {
    vpc_id = aws_vpc.commonSaaSAP.id
    tags = {
        Name = "private_rt2"
        Owner = "hamada"
        Product = "mendixTest"
    }
}

resource "aws_route" "private_route2" {
    route_table_id = aws_route_table.private_rt2.id
    nat_gateway_id = aws_nat_gateway.for_eks_fargate2.id
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_b_assoc" {
    subnet_id = aws_subnet.private_ap_b.id
    route_table_id = aws_route_table.private_rt2.id
}

##################
#IAM role for EKS cluster
##################
resource "aws_iam_role" "eksclusterRole" {
    name = "eksClusterRole"
    assume_role_policy = data.aws_iam_policy_document.ekscluster_assume.json
}

data "aws_iam_policy_document" "ekscluster_assume" {
    statement {
        effect = "Allow"
        actions = [
            "sts:AssumeRole",
        ]
        principals {
          type = "Service"
          identifiers = ["eks.amazonaws.com"] 
        }
    }
}

resource "aws_iam_role_policy_attachment" "ekscluster1" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.eksclusterRole.name
}

resource "aws_iam_role_policy_attachment" "ekscluster2" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
    role = aws_iam_role.eksclusterRole.name
}

##################
#IAM Role for EKS pod execution
##################

resource "aws_iam_role" "ekspodexecution" {
    name = local.ekspodexecution_role_name
    assume_role_policy = data.aws_iam_policy_document.ekspodexecution_assume.json
}

data "aws_iam_policy_document" "ekspodexecution_assume" {
    statement {
      effect = "Allow"
      actions = [
          "sts:AssumeRole",
        ]
        principals {
          type = "Service"
          identifiers = [
              "eks-fargate-pods.amazonaws.com",
          ]
        }
    }
}

resource "aws_iam_role_policy_attachment" "ekspodexecution1" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
    role = aws_iam_role.ekspodexecution.name
}

##################
#EKS
##################
resource "aws_eks_cluster" "mendix_cluster" {
    depends_on = [
        aws_iam_role_policy_attachment.ekscluster1,
        aws_iam_role_policy_attachment.ekscluster2,
        aws_cloudwatch_log_group.eks_cluster,
    ]
    name = local.eks_cluster_name
    role_arn = aws_iam_role.eksclusterRole.arn
    version = "1.19"
    vpc_config {
        subnet_ids = [
            aws_subnet.public_ap_a.id,
            aws_subnet.public_ap_b.id,
            aws_subnet.private_ap_a.id,
            aws_subnet.private_ap_b.id,
        ]
    }
    enabled_cluster_log_types = [
        "api",
        "audit",
        "authenticator",
        "controllerManager",
        "scheduler",
    ]
}

resource "aws_eks_fargate_profile" "kubesystem" {
    cluster_name = aws_eks_cluster.mendix_cluster.name
    fargate_profile_name = local.eks_fargate_kubesystem_profaile_name
    pod_execution_role_arn = aws_iam_role.ekspodexecution.arn
    subnet_ids = [
        aws_subnet.private_ap_a.id,
        aws_subnet.private_ap_b.id,
    ]
    selector {
        namespace = "default"
    }
    selector {
        namespace = "kube-system"
    }
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
    name = "/aws/eks/${local.eks_cluster_name}/cluster"
    retention_in_days = 3
}

##################
#Local file for kubernetes config
##################
resource "local_file" "kubeconfig" {
    filename = "./output_files/kubeconfig.yaml"
    content = data.template_file.kubeconfig.rendered
}

data "template_file" "kubeconfig" {
    template = file("${path.module}/kubernetes_template/01_kubeconfig_template.yaml")
    vars = {
        eks_certificate_authority_data = aws_eks_cluster.mendix_cluster.certificate_authority.0.data
        eks_cluster_endpoint = aws_eks_cluster.mendix_cluster.endpoint
        eks_cluster_arn = aws_eks_cluster.mendix_cluster.arn
        eks_cluster_region = var.region
        eks_cluster_name = local.eks_cluster_name
    }
}

##################
#local file for alb ingress controller
##################
resource "local_file" "alb_ingress_controller" {
    filename = "./ouput_files/alb-ingress-controller.yaml"
    content = data.template_file.alb_ingress_controller.rendered
}

data "template_file" "alb_ingress_controller" {
    template = file("${path.module}/kubernetes_template/11_alb-ingress-controller.yaml")
    vars = {
        eks_cluster_name = aws_eks_cluster.mendix_cluster.name
        vpc_id = aws_vpc.commonSaaSAP.id
        region_name = var.region
    }
}

##################
#local file for RBAC Role
##################
resource "local_file" "rbac_role" {
    filename = "./output_files/rbac-role.yaml"
    content = data.template_file.rbac_role.rendered
}

data "template_file" "rbac_role" {
    template = file("${path.module}/kubernetes_template/12_rbac-role.yaml")
}

##################
#local file for nginx deployment
##################
resource "local_file" "nginx_deployment" {
    filename = "./output_files/nginx-deployment.yaml"
    content = data.template_file.nginx_deployment.rendered
}

data "template_file" "nginx_deployment" {
    template = file("${path.module}/kubernetes_template/13_nginx-deployment.yaml")

    vars = {
        eks_fargate_profile_name = aws_eks_fargate_profile.kubesystem.fargate_profile_name
    }
}

##################
#local file for nginx service
##################
resource "local_file" "nginx_service" {
    filename = "./output_files/nginx_service.yaml"
    content = data.template_file.nginx_service.rendered
}

data "template_file" "nginx_service" {
    template = file("${path.module}/kubernetes_template/14_nginx-service.yaml")
}

##################
#local file for nginx ingress
##################
resource "local_file" "nginx_ingress" {
    filename = "./output_files/nginx-ingress.yaml"
    content = data.template_file.nginx_ingress.rendered
}

data "template_file" "nginx_ingress" {
    template = file("${path.module}/kubernetes_template/15_nginx-ingress.yaml")
}

##################
#rewrite coreDNS for fargate
##################
resource "null_resource" "coredns_patch" {
    depends_on = [
    aws_eks_fargate_profile.kubesystem,
    local_file.kubeconfig,
    local_file.alb_ingress_controller,
    local_file.rbac_role,
    local_file.nginx_deployment,
    local_file.nginx_ingress,
    local_file.nginx_service,
    ]
    provisioner "local-exec" {
        environment = {
            KUBECONFIG = local_file.kubeconfig.filename
        }
        command = "kubectl patch deployment coredns -n kube-system --type json -p='[{\"op\": \"remove\", \"path\": \"/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type\"}]'"
        on_failure = fail
    }
}

resource "null_resource" "coredns_restart" {
    depends_on = [null_resource.coredns_patch]
    
    provisioner "local-exec" {
        environment = {
            KUBECONFIG = local_file.kubeconfig.filename
        }
        command = "kubectl rollout restart -n kube-system deployment coredns"
        on_failure = fail
    }
}

##################
#IAM policy and id provider for ALB
##################
data "tls_certificate" "for_eks_fargate_pod" {
    url = aws_eks_cluster.mendix_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "for_eks_fargate_pod" {
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = [data.tls_certificate.for_eks_fargate_pod.certificates[0].sha1_fingerprint]
    url             = aws_eks_cluster.mendix_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_policy" "alb_ingress_controller" {
  name   = local.eksalbingresscontroller_policy_name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "acm:DescribeCertificate",
                "acm:ListCertificates",
                "acm:GetCertificate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DeleteSecurityGroup",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVpcs",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DeleteRule",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeTags",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:ModifyRule",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:RemoveTags",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:SetWebAcl"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole",
                "iam:GetServerCertificate",
                "iam:ListServerCertificates"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "waf-regional:GetWebACLForResource",
                "waf-regional:GetWebACL",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "tag:GetResources",
                "tag:TagResources"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "waf:GetWebACL"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "shield:DescribeProtection",
                "shield:GetSubscriptionState",
                "shield:DeleteProtection",
                "shield:CreateProtection",
                "shield:DescribeSubscription",
                "shield:ListProtections"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "null_resource" "create_rbac_role" {
    depends_on = [null_resource.coredns_restart]

    provisioner "local-exec" {
        environment = {
            KUBECONFIG = local_file.kubeconfig.filename
        }
        command = "kubectl apply -f ./output_files/rbac-role.yaml"

        on_failure = fail
    }
}

resource "null_resource" "create_iamserviceaccount" {
    depends_on = [null_resource.create_rbac_role]

    provisioner "local-exec" {
        command = "eksctl create iamserviceaccount --name alb-ingress-controller --namespace kube-system --cluster ${aws_eks_cluster.mendix_cluster.name} --attach-policy-arn ${aws_iam_policy.alb_ingress_controller.arn} --approve"

        on_failure = fail
    }
}

resource "null_resource" "create_alb_ingress_controller" {
    depends_on = [null_resource.create_iamserviceaccount]

    provisioner "local-exec" {
        environment = {
        KUBECONFIG = local_file.kubeconfig.filename
        }
        command = "kubectl apply -f ./output_files/alb-ingress-controller.yaml"

        on_failure = fail
    }
}

resource "null_resource" "nginx_service" {
    depends_on = [null_resource.create_alb_ingress_controller]

    provisioner "local-exec" {
        environment = {
        KUBECONFIG = local_file.kubeconfig.filename
        }
        command = "kubectl apply -f ./output_files/nginx-service.yaml"

        on_failure = fail
    }
}

resource "null_resource" "nginx_deployment" {
    depends_on = [null_resource.nginx_service]

    provisioner "local-exec" {
        environment = {
        KUBECONFIG = local_file.kubeconfig.filename
        }
        command = "kubectl apply -f ./output_files/nginx-deployment.yaml"

        on_failure = fail
    }
}

resource "null_resource" "nginx_ingress" {
    depends_on = [null_resource.nginx_deployment]

    provisioner "local-exec" {
        environment = {
        KUBECONFIG = local_file.kubeconfig.filename
        }
        command = "kubectl apply -f ./output_files/nginx-ingress.yaml"

        on_failure = fail
    }
}