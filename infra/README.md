# Static site infrastructure

The main stack. For each entry in `var.sites` it creates a private S3 origin
bucket, a CloudFront distribution with Origin Access Control, a shared security
headers policy, and — when custom domains are configured — an ACM certificate
and Route 53 alias records. Site files under `../sites/<name>` are uploaded as
managed objects.

GitHub Actions applies this stack on every push to `master`. Applying it by hand
should be rare.

## Prerequisites

- Terraform 1.10 or newer (the S3 backend uses native `use_lockfile` locking)
- [`infra/bootstrap`](bootstrap/README.md) applied, which creates the state
  bucket and the CI roles
- AWS credentials for the target account

## Local plan and apply

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

terraform -chdir=infra init \
  -backend-config="bucket=static-sites-terraform-state-${ACCOUNT_ID}" \
  -backend-config="key=static-sites/terraform.tfstate" \
  -backend-config="region=eu-central-1" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform -chdir=infra plan
terraform -chdir=infra apply
```

`terraform output site_urls` prints the HTTPS URL for each site.

CloudFront caches assets for a day, so after applying content changes outside
the pipeline, invalidate manually:

```bash
terraform -chdir=infra output -json distribution_ids \
  | jq -r '.[]' \
  | xargs -I{} aws cloudfront create-invalidation --distribution-id {} --paths '/*'
```

## Variables

| Variable                 | Default          | Purpose                                                   |
| ------------------------ | ---------------- | --------------------------------------------------------- |
| `aws_region`             | `eu-central-1`   | Region for the origin buckets                              |
| `project_name`           | `static-sites`   | Prefix for bucket names and tags                           |
| `sites`                  | two empty sites  | Map of site name to optional `domain_names` and `route53_zone_id` |
| `error_document`         | `index.html`     | Object returned with a 404 status for 403/404 responses    |
| `cloudfront_price_class` | `PriceClass_100` | Edge coverage                                              |

## Teardown

```bash
terraform -chdir=infra destroy
```

The bootstrap stack is separate and is not removed by this. Its state bucket
carries `prevent_destroy`.
