output "s3_bucket_name" {
  value = aws_s3_bucket.cost_reports.id
}

output "cur_report_name" {
  value = aws_cur_report_definition.cur.report_name
}

output "cloudwatch_dashboard" {
  value = aws_cloudwatch_dashboard.cost_dashboard.dashboard_name
}
