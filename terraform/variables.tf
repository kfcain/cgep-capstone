variable "aws_region" {
  type        = string
  description = "AWS region for the starter."
  default     = "us-east-1"
}

variable "enable_monitoring" {
  type        = bool
  description = "Deploy the CloudTrail policy-change detector and SNS alert topic."
  default     = false
}
