# METADATA
# title: CMMC storage protection gates
# custom:
#   framework: cmmc
#   controls: ["SC.L2-3.13.8", "SC.L2-3.13.11", "MP.L2-3.8.9"]
#   severity: high
package compliance.cmmc.storage

import future.keywords

resources := object.get(input, ["planned_values", "root_module", "resources"], [])

resource(address) = r if {
  some r in resources
  r.address == address
}

deny contains "GAP-01: S3 must use customer-managed SSE-KMS" if {
  sse := resource("aws_s3_bucket_server_side_encryption_configuration.uploads").values
  not sse.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
}

deny contains "GAP-02: DynamoDB must use customer-managed encryption" if {
  table := resource("aws_dynamodb_table.intake").values
  not table.server_side_encryption[0].enabled
}

tls_policy_present if {
  resource("aws_s3_bucket_policy.uploads_tls") != null
}

tls_policy_known if {
  policy := object.get(resource("aws_s3_bucket_policy.uploads_tls").values, "policy", null)
  policy != null
}

has_tls_deny if {
  tls_policy_known
  policy := json.unmarshal(resource("aws_s3_bucket_policy.uploads_tls").values.policy)
  some statement in policy.Statement
  statement.Effect == "Deny"
  statement.Condition.Bool["aws:SecureTransport"] == "false"
}

deny contains "GAP-03: S3 must deny non-TLS transport" if {
  not tls_policy_present
}

deny contains "GAP-03: S3 must deny non-TLS transport" if {
  tls_policy_known
  not has_tls_deny
}

deny contains "GAP-04: S3 uploads must have versioning enabled" if {
  not resource("aws_s3_bucket_versioning.uploads").values.versioning_configuration[0].status == "Enabled"
}
