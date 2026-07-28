package compliance.cmmc.boundary_test

import future.keywords

import data.compliance.cmmc.boundary

test_lambda_vpc_gate if {
  "GAP-05: Lambda must run in the governed VPC" in boundary.deny with input as {
    "planned_values": {"root_module": {"resources": [{"address": "aws_lambda_function.intake", "values": {"vpc_config": []}}]}}
  }
}
