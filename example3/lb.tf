resource "aws_lb" "example" {
    name                       = "example"
    load_balancer_type         = "application"
    internal                   = "false"
    idle_timeout               = "60"
    enable_deletion_protection = false
    
    subnets = [
        aws_subnet.public_0.id,
        aws_subnet.public_1.id,
    ]
    
    access_logs {
        bucket = aws_s3_bucket.alb_log.id
        enabled = true
    }
    
    security_groups = [
        module.http_sg.security_group_id,
        module.https_sg.security_group_id,
        module.http_redirect_sg.security_group_id,
    ]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port              = "80"
    protocol          = "HTTP"
    
    default_action {
        type = "fixed-response"
        
        fixed_response {
            content_type = "text/plain"
            message_body = "これは「HTTPです」"
            status_code  = "200"
        }
    }
}


output "alb_dns_name" {
    value = aws_lb.example.dns_name
}   