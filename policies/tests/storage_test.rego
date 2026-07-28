package compliance.cmmc.storage_test

import data.compliance.cmmc.storage

test_storage_sse_gate if {
  "GAP-01: S3 must use customer-managed SSE-KMS" in storage.deny with input as {
    "planned_values": {"root_module": {"resources": [{"address": "aws_s3_bucket_server_side_encryption_configuration.uploads", "values": {"rule": [{"apply_server_side_encryption_by_default": [{"sse_algorithm": "AES256"}]}]}}]}}
  }
}

test_storage_tls_gate if {
  "GAP-03: S3 must deny non-TLS transport" in storage.deny with input as {
    "planned_values": {"root_module": {"resources": [{"address": "aws_s3_bucket_policy.uploads_tls", "values": {"policy": "{}"}}]}}
  }
}
