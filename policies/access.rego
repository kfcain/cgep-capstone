# METADATA
# title: CMMC least-privilege gate
# custom:
#   framework: cmmc
#   controls: ["AC.L2-3.1.5"]
#   severity: high
package compliance.cmmc.access

resources := object.get(input, ["planned_values", "root_module", "resources"], [])

resource(address) = r if {
  some r in resources
  r.address == address
}

deny contains "GAP-07: Lambda data policy must not use wildcard actions" if {
  policy := json.unmarshal(resource("aws_iam_role_policy.lambda_inline").values.policy)
  some statement in policy.Statement
  some action in statement.Action
  endswith(action, "*")
  not startswith(action, "kms:")
}

deny contains "GAP-07: S3 writes must be restricted to uploads/*" if {
  policy := json.unmarshal(resource("aws_iam_role_policy.lambda_inline").values.policy)
  some statement in policy.Statement
  some action in statement.Action
  action == "s3:PutObject"
  not contains(statement.Resource, "/uploads/*")
}
