# ==============================================================================
# HabotConnect Staging Environment Infrastructure
# Position: Junior Cloud & DevOps Engineer Assessment
# Task 1: Terraform Secure Staging Provisioning
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "gcp_project_id" {
  type        = string
  description = "The GCP Project ID where resources will be provisioned."
  default     = "habot-staging-project"
}

variable "gcp_region" {
  type        = string
  description = "The primary region for GCP resources."
  default     = "us-central1"
}

variable "data_analyst_user" {
  type        = string
  description = "User or Group email to grant Least Privilege access."
  default     = "user:analyst@habotconnect.com"
}

# ------------------------------------------------------------------------------
# Provider Configuration
# ------------------------------------------------------------------------------
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ------------------------------------------------------------------------------
# Resource 1: GCS Raw Landing Bucket (DO Raw Landing)
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "raw_landing_bucket" {
  name                     = "${var.gcp_project_id}-do-raw-landing"
  location                 = var.gcp_region
  force_destroy            = false
  public_access_prevention = "enforced"

  # Security: Uniform bucket-level access control
  uniform_bucket_level_access = true

  # Security: Versioning enabled to prevent accidental deletion/overwrites
  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30 # Lifecycle rule to manage data retention/costs
    }
    action {
      type = "Delete"
    }
  }
}

# Least Privilege IAM Policy for GCS Bucket
resource "google_storage_bucket_iam_member" "raw_landing_viewer" {
  bucket = google_storage_bucket.raw_landing_bucket.name
  role   = "roles/storage.objectViewer"
  member = var.data_analyst_user

  # IAM Condition for granular access control
  condition {
    title       = "Restricted_Staging_Access"
    description = "Allows access only during staging operational windows"
    expression  = "request.time < timestamp('2026-12-31T23:59:59Z')"
  }
}

# ------------------------------------------------------------------------------
# Resource 2: BigQuery Dataset (D1 Staged/Enforced)
# ------------------------------------------------------------------------------
resource "google_bigquery_dataset" "staged_dataset" {
  dataset_id                  = "D1_Staged_Enforced"
  friendly_name               = "D1 Staged/Enforced"
  description                 = "Staged and schema-enforced transactional data for analytics."
  location                    = var.gcp_region
  default_table_expiration_ms = 3600000000 # 100 days

  labels = {
    environment = "staging"
    managed_by  = "terraform"
    poka_yoke   = "enforced"
  }
}

# BigQuery Table with Schema Enforcements
resource "google_bigquery_table" "student_onboarding" {
  dataset_id          = google_bigquery_dataset.staged_dataset.dataset_id
  table_id            = "student_onboarding_staged"
  deletion_protection = false

  schema = <<EOF
[
  {
    "name": "student_id",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Unique binary ID for student"
  },
  {
    "name": "lsa_matched",
    "type": "BOOLEAN",
    "mode": "REQUIRED",
    "description": "Binary DCYN flag indicating if LSA is assigned"
  },
  {
    "name": "parent_consent_given",
    "type": "BOOLEAN",
    "mode": "REQUIRED",
    "description": "Binary DCYN flag for consent"
  },
  {
    "name": "region_code",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Geographic access region for Row-Level Security"
  },
  {
    "name": "created_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "Record ingestion timestamp"
  }
]
EOF
}

# BigQuery Table IAM Member for Restricted Analytics Access
resource "google_bigquery_table_iam_member" "analytics_viewer" {
  dataset_id = google_bigquery_dataset.staged_dataset.dataset_id
  table_id   = google_bigquery_table.student_onboarding.table_id
  role       = "roles/bigquery.dataViewer"
  member     = var.data_analyst_user
}

# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------
output "gcs_raw_landing_bucket_name" {
  description = "The name of the GCS Raw Landing bucket"
  value       = google_storage_bucket.raw_landing_bucket.name
}

output "bigquery_dataset_id" {
  description = "The ID of the BigQuery Dataset"
  value       = google_bigquery_dataset.staged_dataset.dataset_id
}
