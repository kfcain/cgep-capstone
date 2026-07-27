# AGENTS.md

## Cursor Cloud specific instructions

This repo is a **Terraform-defined AWS workload** (Acme Health Patient Intake API): VPC, Lambda,
API Gateway v2, DynamoDB, S3. There is no long-running app process — you "run" it by deploying the
infra and POSTing to the intake endpoint. See `README.md`, `WORKLOAD.md`, and the `Makefile` for the
canonical commands (`make deploy | test | destroy`).

### Toolchain (already installed in the snapshot)
`terraform`, `aws`, `docker`, plus LocalStack helpers `tflocal` / `awslocal` (in `/opt/localstack-venv`,
symlinked onto `PATH`). The update script only runs `terraform init` to refresh providers.

### Lint / validate (no cloud needed)
Run in `terraform/`: `terraform fmt -recursive -check` and `terraform validate`. Providers come from
`terraform init` (done by the update script; `.terraform/` is gitignored, so it is re-created per VM).

### Running the workload — two paths

1. **Real AWS (matches README).** `make deploy`/`make test`/`make destroy` need AWS sandbox
   credentials via `AWS_PROFILE` or `AWS_*` env vars. These are **not** present by default; without
   them `terraform plan/apply` fails on the `aws_availability_zones` data source.

2. **LocalStack (no AWS account, used for local dev/demo).** Non-obvious gotchas:
   - The Docker daemon and the LocalStack container are **services**, so start them on a fresh VM
     (they are not in the update script): `sudo service docker start`, then
     `docker run -d --name localstack -p 4566:4566 -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack:3.8.1`.
   - **Pin the community image `localstack/localstack:3.8.1` and run it directly with `docker`.** The
     current LocalStack CLI (2026.x) hard-requires a LocalStack account/`LOCALSTACK_AUTH_TOKEN` and
     will refuse to start, so do not use `localstack start`.
   - Deploy with `tflocal` (wraps `terraform`, injects `:4566` endpoints + `test/test` creds). Work in
     a throwaway copy of `terraform/` so the generated `localstack_providers_override.tf` never touches
     the repo. Export `LOCALSTACK_ACKNOWLEDGE_ACCOUNT_REQUIREMENT=1` for tflocal/awslocal calls.
   - **`apigatewayv2` (HTTP API) is LocalStack Pro-only**, so `aws_apigatewayv2_*` resources fail on
     community; everything else (VPC, Lambda, DynamoDB, S3, IAM) deploys. To exercise the core intake
     flow, invoke the deployed Lambda directly with an API Gateway v2 proxy event
     (`awslocal lambda invoke --payload <event.json>`), then verify the item in DynamoDB and the
     attachment object in S3. This reproduces exactly what API Gateway would forward to the handler.
