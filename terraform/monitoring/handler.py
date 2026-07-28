"""CloudTrail policy-change detector used by the optional monitoring stack."""

import json
import logging
import os
from datetime import datetime, timezone

import boto3


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
SNS = boto3.client("sns")
TOPIC_ARN = os.environ.get("ALERT_TOPIC_ARN", "")


def handler(event, _context):
    """Normalize a security-sensitive CloudTrail event and alert on it."""
    detail = event.get("detail", {})
    identity = detail.get("userIdentity", {})
    finding = {
        "detected_at": datetime.now(timezone.utc).isoformat(),
        "event_id": event.get("id"),
        "event_source": detail.get("eventSource"),
        "event_name": detail.get("eventName"),
        "region": detail.get("awsRegion"),
        "principal": identity.get("arn") or identity.get("principalId"),
        "source_ip": detail.get("sourceIPAddress"),
        "resources": detail.get("resources", []),
    }
    message = json.dumps(finding, sort_keys=True, default=str)
    LOGGER.warning("CGE-P policy-change finding: %s", message)

    if TOPIC_ARN:
        SNS.publish(
            TopicArn=TOPIC_ARN,
            Subject="CGE-P policy change detected",
            Message=message,
        )

    return {"status": "alerted", "event_name": finding["event_name"]}
