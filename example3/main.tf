data "aws_iam_policy_document" "allow_describe_regions" {
    statement {
        effect    = "Allow"
        actions   = ["ec2:DescribeRegions"]
        resources = ["*"]
    }
}


module "describe_region_for_ec2" {
    source     = "./iam_role"
    name       = "describe_region_for_ec2"
    identifier = "ec2.amazonaws.com"
    policy     = data.aws_iam_policy_document.allow_describe_regions.json
}