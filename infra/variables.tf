variable "stage" {
  description = "Deployment stage (prod, dev, or any custom stage name)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region for non-global resources"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = ""
}
