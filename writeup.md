# CGE-P Capstone Write-up — Acme Health Intake

## CMMC Level 2 acknowledgment

This is a training capstone aligned to selected CMMC Level 2 / NIST SP 800-171
practices. It is **not** a CMMC certification, assessment, authorization to
process CUI, or production HIPAA/PHI approval. The deployed test data is
synthetic. A real CUI system would require an approved scope, organizational
policies and evidence, a complete SSP/POA&M, and an authorized assessment
process (including the appropriate C3PAO/assessor path).

Primary framework: CMMC Level 2 against the NIST SP 800-171 Rev. 2 assessment
basis. Rev. 3 is recorded only as a forward-looking transition/compatibility
note; it is not the definitive basis for this capstone.

Because NIST does not publish an authoritative Rev. 2 OSCAL catalog, the repo
contains a small, explicitly labeled Rev. 2 training conversion tied to the
NIST Rev. 2 publication. It must not be represented as an official NIST
catalog. The implementation is mapped to the following practices:

| Practice | Demonstrated implementation |
| --- | --- |
| AC.L2-3.1.5 — least privilege | Lambda policy is limited to DynamoDB `PutItem`, S3 `PutObject` under `uploads/*`, required KMS operations, and DLQ `SendMessage`. |
| AU.L2-3.3.1 — audit records | API Gateway REST stage writes structured access logs to a seven-day CloudWatch log group. |
| MP.L2-3.8.9 — protect/recover media | S3 versioning is enabled; recovery and sanitization procedures remain organizational evidence items. |
| SC.L2-3.13.1 — boundary protection | Lambda uses two private subnets, a restricted security group, and VPC gateway/interface endpoints. |
| SC.L2-3.13.8 — transmission confidentiality | S3 explicitly denies requests where `aws:SecureTransport` is false; API traffic is HTTPS. |
| SC.L2-3.13.11 — cryptographic protection | S3 and DynamoDB use the customer-managed KMS key with rotation enabled. |
| SI.L2-3.14.6 — monitoring/detection | API throttling, WAF rate limiting, Lambda active X-Ray tracing, and an SQS dead-letter queue are deployed. |

## System boundary and deployed resources

The AWS training boundary is a dedicated sandbox in region `us-east-1`; the
account identifier is intentionally omitted from this public submission. The
workload is a regional API Gateway REST API defined by
`aws_api_gateway_rest_api.intake`, invoking Lambda inside the VPC defined by
`aws_vpc.main`. The data path is:

```text
HTTPS client
  -> API Gateway REST /prod/intake
     -> WAF rate rule (100 requests/IP/300 seconds)
        -> Lambda (private subnets + SG, X-Ray Active, DLQ)
           -> DynamoDB submissions (customer CMK)
           -> S3 uploads/uploads/* (customer CMK, versioning, TLS deny)
           -> CloudWatch access logs
```

The Lambda role, data key, DLQ, evidence vault, and CloudTrail trail are
referenced by their Terraform resources rather than live names or ARNs. The
DLQ uses 1,209,600-second (14-day) retention and SQS-managed encryption. The
required evidence baseline is an Object Lock vault (GOVERNANCE, one day) and
a multi-region, log-file-validating trail. The deployed vault name is supplied
to CI through the repository variable `EVIDENCE_VAULT` and is intentionally
not embedded in this public write-up.

## Gap status

GAP-01 through GAP-05 and GAP-07 are technically closed in Terraform and
verified by readbacks. GAP-08 is closed with REST-stage access logging,
throttling, and the WAF association. The provider's create call repeatedly
timed out with `WAFUnavailableEntityException`; the AWS association API
succeeded and the resulting composite association was imported into Terraform.
The final Terraform plan reports **No changes** for the WAF/API configuration.

GAP-06 is substantially closed: DLQ, active X-Ray, and observability are
deployed. Reserved concurrency remains a documented residual because the
account quota is exactly 10 and AWS rejects a reservation of 5 when at least 10
unreserved executions must remain. An attempted Service Quotas request for 20
was rejected by AWS's quota API as inconsistent with its default-quota
metadata. This is a quota/support POA&M item, not a reason to claim that
reserved concurrency is enforced.

## Verification evidence

- `terraform validate`: success.
- Final Terraform plan: no changes after the required vault/CloudTrail apply;
  the WAF association is imported and reconciled.
- Rego unit gate: `6 passed, 0 warnings, 0 failures`.
- Rego hardened-plan gate: `14 passed, 1 warning, 0 failures` against
  `terraform/evidence/final-required-plan.json`.
- Negative baseline gate: six failures against
  `terraform/evidence/baseline/starter-plan.json`, demonstrating fail-closed
  detection of the starter gaps.
- Final synthetic POST: HTTP 200 with a generated submission ID (the live ID
  is omitted from the public submission).
- Lambda readback: `State=Active`, `LastUpdateStatus=Successful`,
  `TracingMode=Active`, DLQ target present, and private VPC configuration.
- API stage readback: access log destination present, throttling burst 5/rate
  2, and `webAclArn` populated.
- WAF readback: regional ACL with `ip-rate-limit`, 100/IP/300-second rule.
- Evidence baseline readback: Object Lock `GOVERNANCE/1 day`, versioning
  enabled, CloudTrail logging enabled, multi-region, and log-file validation
  enabled.

The policy gate is in [`policies/`](policies). It contains five CMMC-tagged
Rego policies plus unit tests under `policies/tests/`; the gate carries
CMMC control metadata and checks encryption, TLS, versioning, VPC placement,
resilience, least privilege, API logging/throttling, and WAF configuration.
The rendered source diagrams are [`network-diagram.mmd`](network-diagram.mmd)
and [`data-flow-diagram.mmd`](data-flow-diagram.mmd).
The required CI workflow is [`.github/workflows/grc-gate.yml`](.github/workflows/grc-gate.yml),
and the required Rev. 2 OSCAL component/profile/catalog are under [`oscal/`](oscal).

## What remains before calling the capstone complete

1. Keep the reserved-concurrency quota item open until AWS raises the account
   quota or the design is formally accepted with API throttling plus DLQ/X-Ray
   as the compensating controls.
2. Demonstrate the policy gate in CI (one intentionally failing baseline and
   one passing hardened plan) before any production-like promotion.
3. Submit the repository commit with the required OSCAL, workflow, Terraform,
   Rego, and writeup artifacts. Organizational SSP/procedure evidence is out of
   scope for this code capstone unless the course separately requests it.
4. Decide whether to retain the sandbox resources; destroy them when the
   evidence session is complete to avoid ongoing charges.
