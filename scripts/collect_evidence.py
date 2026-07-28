#!/usr/bin/env python3
"""Collect live AWS readbacks for the capstone evidence bundle.

The script intentionally shells out to the AWS CLI already authenticated by
GitHub Actions. It records provider readbacks, not credentials or Terraform
state, and writes one deterministic JSON document for signing.
"""

import argparse
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def run_aws(*args):
    result = subprocess.run(
        ["aws", *args, "--output", "json"],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def terraform_outputs(directory):
    result = subprocess.run(
        ["terraform", f"-chdir={directory}", "output", "-json"],
        check=True,
        capture_output=True,
        text=True,
    )
    return {key: value["value"] for key, value in json.loads(result.stdout).items()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--terraform-dir", default="terraform")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    outputs = terraform_outputs(args.terraform_dir)
    region = os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION") or "us-east-1"
    api_match = re.search(r"https://([a-z0-9]+)\.execute-api\.", outputs["api_url"])
    if not api_match:
        raise SystemExit("api_url output does not contain an API Gateway identifier")
    api_id = api_match.group(1)
    evidence = {
        "collected_at": datetime.now(timezone.utc).isoformat(),
        "region": region,
        "outputs": outputs,
        "caller": run_aws("sts", "get-caller-identity"),
        "lambda": run_aws("lambda", "get-function", "--function-name", outputs["lambda_function_name"]),
        "dynamodb": run_aws("dynamodb", "describe-table", "--table-name", outputs["intake_table"]),
        "uploads_encryption": run_aws(
            "s3api", "get-bucket-encryption", "--bucket", outputs["uploads_bucket"]
        ),
        "uploads_versioning": run_aws(
            "s3api", "get-bucket-versioning", "--bucket", outputs["uploads_bucket"]
        ),
        "api_stage": run_aws("apigateway", "get-stage", "--rest-api-id", api_id, "--stage-name", "prod"),
        "cloudtrail": run_aws("cloudtrail", "get-trail-status", "--name", outputs["cloudtrail_name"]),
        "waf": run_aws(
            "wafv2", "list-web-acls", "--scope", "REGIONAL", "--region", region
        ),
    }
    destination = Path(args.output)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n")
    print(f"wrote live evidence to {destination}")


if __name__ == "__main__":
    main()
