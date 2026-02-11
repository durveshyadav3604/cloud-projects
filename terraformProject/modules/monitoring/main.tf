
# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts1"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.email
}
# Create IAM role for cloudwatch to SSN email
resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.alerts.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}


# CloudWatch Alarms for ASG EC2 (high-cpu)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-EC2-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn,
    var.scale_out_policy_arn
  ]
}
#CloudWatch Alarms for (low-cpu)
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-EC2-LowCPU"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 25

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn,
    var.scale_in_policy_arn
  ]
  depends_on = [
    aws_sns_topic_subscription.email_sub
  ]
}
#Memory Alarm
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.project_name}-HighMemory"
  namespace           = "CWAgent"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
#Disk Alarm
resource "aws_cloudwatch_metric_alarm" "high_disk" {
  alarm_name          = "${var.project_name}-HighDisk"
  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# CloudWatch Alarms for ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-ALB-5XXErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm when ALB returns 5xx errors"
  dimensions = {
    TargetGroup = var.alb_target_group_arn
    LoadBalancer = var.alb_arn
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}
#ALB Unhealthy Host Alarm
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name          = "${var.project_name}-ALB-UnhealthyHosts"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Average"
  period              = 300

  dimensions = {
    TargetGroup  = var.alb_target_group_arn
    LoadBalancer = var.alb_arn
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}


# ======================
# CloudWatch Dashboard
# ======================
resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${var.project_name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name ]
          ]
          period = 300
          stat = "Average"
          region = "ap-south-1"
          title = "EC2 CPU Utilization"
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", var.alb_target_group_arn, "LoadBalancer", var.alb_arn ]
          ]
          period = 300
          stat = "Sum"
          region = "ap-south-1"
          title = "ALB 5XX Errors"
        }
      },
      {
            type = "metric",
            x = 12,
            y = 0,
            width = 12,
            height = 6,
            properties = {
            metrics = [
                [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.alb_target_group_arn, "LoadBalancer", var.alb_arn ],
                [ ".", "UnHealthyHostCount", ".", ".", ".", "." ]
              ],
            period = 300,
            stat = "Average",
            region = "ap-south-1",
            title = "ALB Target Health"
        }
      },
      {
            type = "metric",
            x = 12,
            y = 6,
            width = 12,
            height = 6,
            properties = {
            metrics = [
                [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name ],
                [ ".", "GroupDesiredCapacity", ".", "." ]
              ],
            period = 300,
            stat = "Average",
            region = "ap-south-1",
            title = "ASG Capacity"
        }
      },
      {
            type = "metric",
            x = 0,
            y = 12,
            width = 12,
            height = 6,
            properties = {
            metrics = [
                ["CWAgent","mem_used_percent","AutoScalingGroupName",var.asg_name]
              ],
            stat = "Average",
            period = 300,
            region = "ap-south-1",
            title = "EC2 Memory Utilization"
        }
      },
        {
            type = "metric",
            x = 12,
            y = 12,
            width = 12,
            height = 6,
            properties = {
            metrics = [
                ["CWAgent","disk_used_percent","AutoScalingGroupName",var.asg_name]
            ],
            stat = "Average",
            period = 300,
            region = "ap-south-1",
            title = "EC2 Disk Utilization"
        }
      }
    ]
  })
}