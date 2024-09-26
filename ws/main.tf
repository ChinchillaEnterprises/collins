# Configure the Databricks provider
terraform {
  required_providers {
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.5.8"
    }
  }
}

# Create a Databricks cluster
resource "databricks_cluster" "example_cluster" {
  cluster_name            = "example-cluster"
  spark_version           = "7.3.x-scala2.12"
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 3
  }
}

# Create a Databricks job
resource "databricks_job" "example_job" {
  name                = "example-job"
  existing_cluster_id = databricks_cluster.example_cluster.id
  
  notebook_task {
    notebook_path = "/Shared/example_notebook"
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