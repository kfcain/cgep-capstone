package compliance.cmmc.audit_test

import data.compliance.cmmc.audit

test_audit_log_gate if {
  "GAP-08: API Gateway stage must emit access logs" in audit.deny with input as {
    "planned_values": {"root_module": {"resources": [{"address": "aws_api_gateway_stage.default", "values": {"access_log_settings": [], "web_acl_arn": ""}}, {"address": "aws_api_gateway_method_settings.intake", "values": {"settings": [{"throttling_burst_limit": 0}]}}, {"address": "aws_wafv2_web_acl.intake", "values": {"rule": []}}]}}
  }
}
