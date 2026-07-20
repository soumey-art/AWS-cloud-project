# 1. CLOUDWATCH LOG GROUP
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ec2/app-logs"
  retention_in_days = 7

  tags = {
    Project     = "Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# 2. SNS TOPIC + SUBSCRIPTION
resource "aws_sns_topic" "alarm_notifications" {
  name = "rith-cloud-alarms"

  tags = {
    Project     = "Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# 3. CLOUDWATCH DASHBOARD
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Rith-Cloud-Project-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.app_asg.name]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region,
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.application_lb.name],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", aws_lb.application_lb.name],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.application_lb.name]
          ],
          period = 300,
          stat   = "Sum",
          region = var.aws_region,
          title  = "ALB Requests & Errors"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.app_target_group.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.app_target_group.arn_suffix]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region,
          title  = "Healthy / Unhealthy Hosts"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.application_lb.name]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region,
          title  = "Target Response Time"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 12,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main.identifier],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.main.identifier],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.main.identifier]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region,
          title  = "RDS Metrics"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 12,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupTotalInstances", "AutoScalingGroupName", aws_autoscaling_group.app_asg.name]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region,
          title  = "ASG Instance Count"
        }
      }
    ]
  })
}

# 4. ALARM: High CPU > 70% for 10 min
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name                = "cpu-high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 70
  alarm_description         = "Average EC2 CPU > 70% for 10 minutes"
  alarm_actions             = [aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [aws_sns_topic.alarm_notifications.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_notifications.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  tags = {
    Project     = "Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# 5. ALARM: Unhealthy Host Count >= 1
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name                = "unhealthy-hosts"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "UnHealthyHostCount"
  namespace                 = "AWS/ApplicationELB"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 1
  alarm_description         = "At least 1 unhealthy target detected"
  alarm_actions             = [aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [aws_sns_topic.alarm_notifications.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_notifications.arn]

  dimensions = {
    TargetGroup = aws_lb_target_group.app_target_group.arn_suffix
  }

  tags = {
    Project     = "Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# 6. ALARM: Target 5XX above threshold
resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name                = "target-5xx"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "HTTPCode_Target_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = 300
  statistic                 = "Sum"
  threshold                 = 10
  alarm_description         = "Target 5XX errors > 10 in 10 minutes"
  alarm_actions             = [aws_sns_topic.alarm_notifications.arn]
  ok_actions                = [aws_sns_topic.alarm_notifications.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_notifications.arn]

  dimensions = {
    LoadBalancer = aws_lb.application_lb.name
  }

  tags = {
    Project     = "Cloud-Project"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
