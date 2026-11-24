# Cost

Rough monthly figures for `ap-southeast-2` (Sydney) running 24/7, rounded.
They're approximations from AWS list prices for orientation only and will
drift; the plan workflow prices every change against current prices with
Infracost.

| Item | dev | prod |
|---|---|---|
| EKS control plane | ~$75 | ~$75 |
| Nodes | ~$60 (2× t3.large spot) | ~$300 (3× m6i.large on-demand) |
| NAT gateways (+ data) | ~$45 (1) | ~$135 (3) |
| ElastiCache | ~$15 (1× t4g.micro) | ~$60 (2× t4g.small) |
| EBS (nodes, Ollama, Prometheus) | ~$15 | ~$40 |
| Logs, KMS, Secrets Manager | ~$10 | ~$20 |
| **Approximate total** | **~$220** | **~$630** |

Account baseline (once): GuardDuty, Security Hub, Config and CloudTrail are
usage-based and typically under $20/month for an account this size.

## Keeping it cheap

- Bring dev up for a demo, then tear it down: `make destroy ENV=dev`. A few
  hours costs a few dollars.
- Everything except the account baseline is in the per-env stacks, so destroy
  really does stop the meter.
- The S3 gateway endpoint keeps image pulls from S3-backed registries and
  state access off the NAT gateway, which bills per GB.
- Budgets: set an AWS Budget alert on the account before the first apply.
