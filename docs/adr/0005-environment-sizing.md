# 5. Dev optimises for cost, prod for resilience

Status: accepted

| Choice | dev | prod | Why |
|---|---|---|---|
| NAT gateways | 1 shared | 1 per AZ | One AZ outage takes dev egress down; acceptable for dev |
| Nodes | Spot, 1–3 | On-demand, 3–9 | Spot interruptions are fine where nobody's paged |
| Redis | 1 node | Primary + replica, auto-failover | |
| Gateway replicas | 1–3 | 3–12, PDB min 2 | |
| Prometheus retention | 3 days | 15 days | |

The structure is identical; only `envs/<env>/*.tfvars` and the chart's
`values-<env>.yaml` differ. Anything that works in dev exercises the same code
as prod.
