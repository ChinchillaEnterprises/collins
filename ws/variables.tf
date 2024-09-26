variable "databricks_account_id" {
  description = "The Databricks account ID"
  type        = string
}

variable "databricks_host" {
  description = "The Databricks host URL"
  type        = string
}

variable "databricks_client_id" {
  description = "The Databricks client ID for authentication"
  type        = string
}

variable "databricks_client_secret" {
  description = "The Databricks client secret for authentication"
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "The AWS region where the Databricks workspace will be created"
  type        = string
  default     = "us-west-2"
}

variable "workspace_name" {
  description = "The name of the Databricks workspace"
  type        = string
  default     = "My Terraform Workspace"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}