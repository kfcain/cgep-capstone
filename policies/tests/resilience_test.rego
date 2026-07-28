package compliance.cmmc.resilience_test

import future.keywords.in

import data.compliance.cmmc.resilience

test_dlq_gate if {
  "GAP-06: Lambda must have a dead-letter target" in resilience.deny with input as {
    "planned_values": {"root_module": {"resources": [{"address": "aws_lambda_function.intake", "values": {"dead_letter_config": [], "tracing_config": [{"mode": "Active"}], "reserved_concurrent_executions": -1}}]}}
  }
}
