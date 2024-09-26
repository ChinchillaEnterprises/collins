# Configure the Databricks provider
terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.5.8"
    }
  }
}

# Provider configuration
provider "databricks" {
  # Configuration options
  # You can set these using environment variables or a .tfvars file
  # host  = var.databricks_host
  # token = var.databricks_token
}

# Variables for easy configuration
variable "node_type_id" {
  description = "The node type ID for the Databricks cluster"
  type        = string
  default     = "r5.xlarge"  # A commonly available instance type on AWS
}

variable "spark_version" {
  description = "The Spark version for the Databricks cluster"
  type        = string
  default     = "10.4.x-scala2.12"  # A recent version of Spark
}

variable "cluster_name" {
  description = "The name of the Databricks cluster"
  type        = string
  default     = "example-cluster"
}

variable "job_name" {
  description = "The name of the Databricks job"
  type        = string
  default     = "example-job"
}

variable "notebook_path" {
  description = "The path to the notebook to run in the job"
  type        = string
  default     = "/Shared/example_notebook"
}

# Create a Databricks cluster
resource "databricks_cluster" "example_cluster" {
  cluster_name            = var.cluster_name
  spark_version           = var.spark_version
  node_type_id            = var.node_type_id
  autotermination_minutes = 20
  
  autoscale {
    min_workers = 1
    max_workers = 3
  }

  aws_attributes {
    availability           = "SPOT_WITH_FALLBACK"
    zone_id                = "auto"
    first_on_demand        = 1
    spot_bid_price_percent = 100
    ebs_volume_type        = "GENERAL_PURPOSE_SSD"
    ebs_volume_count       = 1
    ebs_volume_size        = 100
  }
}

# Create a Databricks job
resource "databricks_job" "example_job" {
  name                = var.job_name
  existing_cluster_id = databricks_cluster.example_cluster.id
  
  notebook_task {
    notebook_path = var.notebook_path
  }
  
  schedule {
    quartz_cron_expression = "0 0 10 ? * MON-FRI"
    timezone_id            = "America/New_York"
  }
}

# Output the cluster ID and job ID
output "cluster_id" {
  value = databricks_cluster.example_cluster.id
}

output "job_id" {
  value = databricks_job.example_job.id
}