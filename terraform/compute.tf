# 1. APPLICATION LOAD BALANCER (ALB)
# Receives HTTP traffic on port 80 and spans two public Availability Zones
resource "aws_lb" "application_lb" {
  name               = "rith-project-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Project     = "Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# 2. ALB TARGET GROUP
# Configured to look for Donal's application port and track the /health endpoint.
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-target-group"
  port     = var.app_port # Coordinate with Donal for his application port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health" # Mandatory path
    protocol            = "HTTP"
    matcher             = "200" # Expects HTTP 200
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# 3. ALB HTTP LISTENER
# Listens on port 80 and routes all incoming public traffic to your targets.
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80" # Mandatory entry port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# 4. EC2 LAUNCH TEMPLATE
# The blueprint blueprint that handles instances deployment.
resource "aws_launch_template" "app_launch_template" {
  name_prefix   = "app-template"
  image_id      = "ami-0fd6240f599091088" # Amazon Linux 2023 x86_64
  instance_type = "t2.micro"

  # Attached profile managed by Soumey for CloudWatch and S3 access rules
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  # Startup runtime initialization script (Coordinate with Donal)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Pass critical environment flags down to Donal's web runtime ecosystem
export DB_HOST=${aws_db_instance.main.endpoint}
export S3_BUCKET_NAME=${aws_s3_bucket.main.bucket}
              
              # Donal's custom app boot commands and log pipeline anchors go below
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 5. AUTO SCALING GROUP (ASG)
# Deploys and manages instances across two private Availability Zones.
resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "rith-asg-"
  desired_capacity    = 2 # Mandatory baseline requirement
  min_size            = 2 # Minimum boundary
  max_size            = 4 # Maximum ceiling threshold
  target_group_arns   = [aws_lb_target_group.app_target_group.arn]
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }

  # Leverages ELB health engine checks instead of default basic hypervisor checks
  health_check_type         = "ELB"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Project"
    value               = "Cloud-Project"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "EC2 Web Server"
    propagate_at_launch = true
  }
}

# 6. TARGET TRACKING SCALING POLICY
# Dynamically maintains pool scalability using CPU thresholds.
resource "aws_autoscaling_policy" "cpu_target_tracking_policy" {
  name                   = "cpu-utilization-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0 # Scales up or down to sustain 60% average CPU workload
  }
}
