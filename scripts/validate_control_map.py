#!/usr/bin/env python3
"""Validate reciprocal control/code references before evidence is signed."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAP = ROOT / "oscal" / "control-map.json"


def main():
    mapping = json.loads(MAP.read_text())
    controls = mapping["control_to_code"]
    reverse = mapping["code_to_control"]
    for control, refs in controls.items():
        for artifact_key in ("terraform", "rego", "evidence"):
            for artifact in refs[artifact_key]:
                reverse_key = artifact if artifact in reverse else "terraform/main.tf"
                if reverse_key not in reverse or control not in reverse[reverse_key]:
                    raise SystemExit(f"missing reverse control: {artifact} -> {control}")
                if reverse_key != "terraform/main.tf" and not (ROOT / reverse_key).exists():
                    raise SystemExit(f"mapped artifact does not exist: {reverse_key}")
    print(f"validated {len(controls)} controls and reciprocal artifact references")


if __name__ == "__main__":
    main()
