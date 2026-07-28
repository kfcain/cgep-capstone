package compliance.cmmc.access_test

import data.compliance.cmmc.access

test_wildcard_action_gate if {
  "GAP-07: Lambda data policy must not use wildcard actions" in access.deny with input as {
    "planned_values": {"root_module": {"resources": [{"address": "aws_iam_role_policy.lambda_inline", "values": {"policy": "{\"Statement\":[{\"Action\":[\"s3:*\"]}]}"}}]}}
  }
}
