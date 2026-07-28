# METADATA
# title: CMMC API audit and WAF gate
# custom:
#   framework: cmmc
#   controls: ["AU.L2-3.3.1"]
#   severity: high
package compliance.cmmc.audit

resources := object.get(input, ["planned_values", "root_module", "resources"], [])

resource(address) = r if {
  some r in resources
  r.address == address
}

deny contains "GAP-08: API Gateway stage must emit access logs" if {
  count(resource("aws_api_gateway_stage.default").values.access_log_settings) == 0
}

deny contains "GAP-08: API Gateway must throttle requests" if {
  resource("aws_api_gateway_method_settings.intake").values.settings[0].throttling_burst_limit <= 0
}

deny contains "GAP-08: REST API stage must have a WAF association" if {
  not startswith(resource("aws_api_gateway_stage.default").values.web_acl_arn, "arn:aws:wafv2:")
}

has_rate_limit if {
  waf := resource("aws_wafv2_web_acl.intake").values
  some rule in waf.rule
  rule.name == "ip-rate-limit"
  rule.statement[0].rate_based_statement[0].limit <= 100
  rule.statement[0].rate_based_statement[0].aggregate_key_type == "IP"
}

deny contains "GAP-08: WAF must include an IP rate limit no greater than 100 requests per 5 minutes" if {
  not has_rate_limit
}
