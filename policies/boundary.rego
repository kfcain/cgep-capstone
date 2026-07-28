# METADATA
# title: CMMC workload boundary gate
# custom:
#   framework: cmmc
#   controls: ["SC.L2-3.13.1"]
#   severity: high
package compliance.cmmc.boundary

import future.keywords.in

resources := object.get(input, ["planned_values", "root_module", "resources"], [])

resource(address) = r if {
  some r in resources
  r.address == address
}

deny contains "GAP-05: Lambda must run in the governed VPC" if {
  lambda := resource("aws_lambda_function.intake").values
  count(lambda.vpc_config) == 0
}

deny contains "GAP-05: Lambda must use private subnets and a security group" if {
  lambda := resource("aws_lambda_function.intake").values
  count(lambda.vpc_config[0].subnet_ids) < 2
}
