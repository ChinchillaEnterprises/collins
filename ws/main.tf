terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.52.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  # Credentials can be set via environment variables, shared credentials file, or other methods.
}

# Configure the Databricks Provider
provider "databricks" {
  # Ensure that the Databricks provider has the necessary configurations
  # such as host, token, etc. These can be set via environment variables
  # or directly within the provider block.
}

# Variables (You can define these in a separate variables.tf file)
variable "aws_region" {
  description = "The AWS region where the S3 bucket will be created."
  type        = string
  default     = "us-east-1" # Change as needed
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket to create."
  type        = string
  default     = "weather-data-bucket-collin-tf" # Ensure this is globally unique
}

# Create AWS S3 Bucket
resource "aws_s3_bucket" "weather_data_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_policy" "weather_data_bucket_policy" {
  bucket = aws_s3_bucket.weather_data_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::904233133154:role/databricks-workspace-stack-aa94c-role"
        }
        Action = [
          "*"
        ]
        Resource = [
          aws_s3_bucket.weather_data_bucket.arn,
          "${aws_s3_bucket.weather_data_bucket.arn}/*"
        ]
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.weather_data_bucket
  ]
}


# Create Catalog with Managed Location
resource "databricks_catalog" "weather_catalog" {
  name        = "weather_catalog"
  comment     = "This catalog is managed by Terraform for weather data."
  properties = {
    purpose = "weather_data_processing"
  }
  storage_root = "s3://${aws_s3_bucket.weather_data_bucket.bucket}" # Reference the created S3 bucket

  # Ensure the catalog is created after the S3 bucket
  depends_on = [
    aws_s3_bucket.weather_data_bucket
  ]
}

# Create Schema within the Catalog
resource "databricks_schema" "weather_data_schema" {
  catalog_name = databricks_catalog.weather_catalog.name
  name         = "weather_data"
  comment      = "This schema is managed by Terraform for weather data processing."
  properties = {
    kind = "analytics"
  }

  # Ensure the schema is created after the catalog
  depends_on = [
    databricks_catalog.weather_catalog
  ]
}

# Fetch Current User Information
data "databricks_current_user" "me" {}

# Fetch Latest LTS Spark Version
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

# Fetch Smallest Node Type with Local Disk
data "databricks_node_type" "smallest" {
  local_disk = true
}

# Create Notebook for Weather Data Processing
resource "databricks_notebook" "weather_data" {
  path           = "${data.databricks_current_user.me.home}/weather_data_processing"
  language       = "PYTHON"
  content_base64 = base64encode(<<-EOT
    # Weather Data Processing Notebook

    import requests
    from pyspark.sql.functions import *
    from pyspark.sql.types import *

    # Function to fetch weather data
    def fetch_weather_data():
        # Replace with actual API call to weather service
        # This is a placeholder
        api_key = dbutils.secrets.get(scope="weather_api", key="api_key")
        url = f"https://api.openweathermap.org/data/2.5/weather?q=London&appid={api_key}"
        response = requests.get(url)
        data = response.json()
        return [{"city": data["name"], "temperature": data["main"]["temp"], "humidity": data["main"]["humidity"]}]

    # Fetch weather data
    weather_data = fetch_weather_data()

    # Create DataFrame from weather data
    weather_df = spark.createDataFrame(weather_data)

    # Add timestamp column
    weather_df = weather_df.withColumn("timestamp", current_timestamp())

    # Write to catalog table
    weather_df.write.mode("append").saveAsTable("weather_catalog.weather_data.hourly_weather")

    print("Weather data processed and stored successfully.")
  EOT
  )

  # Ensure the notebook is created after the catalog and schema
  depends_on = [
    databricks_catalog.weather_catalog,
    databricks_schema.weather_data_schema
  ]
}

# Create Job for Weather Data Collection
resource "databricks_job" "weather_data_job" {
  name = "Weather Data Collection Job"

  job_cluster {
    job_cluster_key = "weather_cluster"
    new_cluster {
      num_workers   = 1
      spark_version = data.databricks_spark_version.latest_lts.id
      node_type_id  = data.databricks_node_type.smallest.id
    }
  }

  schedule {
    quartz_cron_expression = "0 0 */10 * * ?" # Run every 10 hours
    timezone_id           = "UTC"
  }

  task {
    task_key = "collect_weather_data"

    notebook_task {
      notebook_path = databricks_notebook.weather_data.path
    }

    job_cluster_key = "weather_cluster"
  }

  email_notifications {
    on_success = [data.databricks_current_user.me.user_name]
    on_failure = [data.databricks_current_user.me.user_name]
  }

  # Ensure the job is created after the catalog, schema, and notebook
  depends_on = [
    databricks_catalog.weather_catalog,
    databricks_schema.weather_data_schema,
    databricks_notebook.weather_data
  ]
}

# Output URLs
output "notebook_url" {
  value = databricks_notebook.weather_data.url
}

output "job_url" {
  value = databricks_job.weather_data_job.url
}

output "s3_bucket_name" {
  description = "The name of the created S3 bucket for weather data."
  value       = aws_s3_bucket.weather_data_bucket.bucket
}

output "s3_bucket_arn" {
  description = "The ARN of the created S3 bucket for weather data."
  value       = aws_s3_bucket.weather_data_bucket.arn
}
