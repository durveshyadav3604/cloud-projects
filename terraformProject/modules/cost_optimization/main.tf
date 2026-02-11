#S3 Bucket for Cost Reports
resource "aws_s3_bucket" "cost_reports" {
  provider      = aws
  bucket        = var.s3_bucket_name
  force_destroy = true
}
resource "aws_s3_bucket_versioning" "cost_reports_versioning" {
  bucket = aws_s3_bucket.cost_reports.id

  versioning_configuration {
    status = "Enabled"
  }
}
# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "cost_reports_lifecycle" {
  bucket = aws_s3_bucket.cost_reports.id

  rule {
    id     = "archive-logs"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}


#Cost and Usage Report (CUR) and This creates daily billing reports in S3.
resource "aws_cur_report_definition" "cur" {
  provider  = aws
  report_name = "${var.project_name}-billing"
  time_unit   = "DAILY"
  format      = "textORcsv"
  compression = "GZIP"
  s3_bucket   = aws_s3_bucket.cost_reports.bucket
  s3_prefix   = "cur"
  s3_region   = "us-east-1"          # Required for CUR
  refresh_closed_reports = true
  report_versioning      = "CREATE_NEW_REPORT"
  additional_schema_elements = ["RESOURCES"]

  depends_on = [aws_s3_bucket_policy.cur_policy]
}

# Add bucket policy for CUR
resource "aws_s3_bucket_policy" "cur_policy" {
  provider = aws
  bucket   = aws_s3_bucket.cost_reports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCURDelivery"
        Effect    = "Allow"
        Principal = { Service = "billingreports.amazonaws.com" }
        Action    = ["s3:GetBucketAcl", "s3:PutObject"]
        Resource  = [
          "${aws_s3_bucket.cost_reports.arn}",
          "${aws_s3_bucket.cost_reports.arn}/*"
        ]
      }
    ]
  })
}

#CloudWatch Dashboard for Cost
resource "aws_cloudwatch_dashboard" "cost_dashboard" {
  provider       = aws
  dashboard_name = "${var.project_name}-cost-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type       = "metric"
        x          = 0
        y          = 0
        width      = 24
        height     = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          period = 86400
          stat   = "Maximum"
          region = "us-east-1"
          title  = "Estimated Charges"
        }
      }
    ]
  })
}

