# METADATA
# title: CMMC Lambda resilience and monitoring gate
# custom:
#   framework: cmmc
#   controls: ["SI.L2-3.14.6"]
#   severity: high
package compliance.cmmc.resilience

import future.keywords

resources := object.get(input, ["planned_values", "root_module", "resources"], [])

resource(address) = r if {
  some r in resources
  r.address == address
}

deny contains "GAP-06: Lambda must have a dead-letter target" if {
  count(resource("aws_lambda_function.intake").values.dead_letter_config) == 0
}

deny contains "GAP-06: Lambda tracing must be Active" if {
  not resource("aws_lambda_function.intake").values.tracing_config[0].mode == "Active"
}

warn contains "GAP-06 residual: reserved concurrency is quota-blocked" if {
  resource("aws_lambda_function.intake").values.reserved_concurrent_executions == -1
}
