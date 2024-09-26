# Databricks Terraform Configuration Requirements

## Overview
This document outlines the requirements and key components of our Databricks infrastructure as defined in the Terraform configuration.

## Important Note
The Databricks workspace must be created via the Databricks console before running the Terraform script. Workspace creation cannot be automated via Terraform from the very beginning due to limitations in the Databricks provider.

## Terraform Configuration (main.tf)

1. Provider Configuration:
   - Uses the Databricks provider (databrickslabs/databricks) version 0.5.8
   - Provider configuration expects host and token to be set via environment variables or a .tfvars file

2. Cluster Configuration:
   - Creates a Databricks cluster named "example-cluster" (configurable)
   - Uses r5.xlarge node type by default (configurable)
   - Spark version: 10.4.x-scala2.12 (configurable)
   - Autoscaling enabled: 1-3 workers
   - Uses AWS SPOT instances with fallback to on-demand
   - EBS volume: 100GB General Purpose SSD

3. Job Configuration:
   - Creates a Databricks job named "example-job" (configurable)
   - Uses the cluster created in step 2
   - Runs a notebook located at "/Shared/example_notebook" (configurable)
   - Scheduled to run at 10:00 AM EST every weekday

4. Variables:
   - Provides variables for easy configuration of cluster and job settings

5. Outputs:
   - Outputs the created cluster ID and job ID for reference

## Original Requirements

1. Create a Terraform script to stand up a cluster in Databricks
2. Create a Terraform script to stand up a job in Databricks

Both of these requirements are met in the current Terraform configuration (main.tf).

## Next Steps

1. Ensure the Databricks workspace is created manually via the Databricks console
2. Set up the necessary environment variables or .tfvars file for the Databricks host and token
3. Review and adjust the variable defaults in main.tf as needed for your specific use case
4. Run the Terraform script to create the cluster and job in your Databricks workspace