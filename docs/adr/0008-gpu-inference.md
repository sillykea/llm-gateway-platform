# 8. GPU inference that scales to zero

Status: accepted

## Context

The gateway can serve self-hosted models alongside hosted APIs, and it has
to for requests with personal data (`pii.mode: route_local`). Until now the
only local model was a small Ollama pod on CPU. A real model needs a GPU,
and a GPU node left on all week for traffic that happens in working hours
mostly bills for idle time.

[inference-autoscaler](https://github.com/sillykea/inference-autoscaler)
works out how to run vLLM on Kubernetes so it scales to zero, and measures
the choices with a simulation. [llm-operator](https://github.com/sillykea/llm-operator)
packages that setup as one resource per model. This ADR is how the platform
adopts both.

## Decision

- **One switch.** `enable_gpu_inference` in the infra tfvars. Off, nothing
  changes. On, Terraform creates Karpenter's controller role (Pod Identity),
  the role GPU nodes run as with its EKS access entry, and the spot
  interruption queue; Argo CD installs KEDA, Karpenter, the NVIDIA device
  plugin, llm-operator and the inference chart.
- **Karpenter for GPU nodes only.** A NodePool of one-GPU g6 (L4) or g5
  (A10G) nodes, tainted so only GPU pods land there, removed a minute after
  they empty. The general node group stays a managed node group. The
  EC2NodeClass selects subnets and the node security group by ID, passed from
  Terraform outputs, so no existing resource needs new tags.
- **Models live in git as LLMDeployments** in `gitops/inference/values.yaml`.
  The operator turns each into vLLM, a KEDA ScaledObject (wake on gateway
  demand, scale on queue depth), a ServiceMonitor and PrometheusRule with a
  budget alert, and a gateway route.
- **The chart's gateway config becomes the base.** With `operatorConfig.enabled`
  the chart writes its config to `llm-gateway-base`, the operator merges in a
  provider and aliases per model and writes `llm-gateway-config`, and the
  gateway mounts that. The operator rolls the gateway by changing one
  annotation on its pod template, under its own server-side apply field
  manager, so Argo CD sees no drift.
- **A new alias first.** The sample model routes `chat-gpu`, falling back to
  the hosted model. `chat-default` and `chat-private` keep their current
  routes until the pool has run under real traffic.

## Sync order

| Wave | Apps |
|---|---|
| -2 | monitoring (Prometheus, which KEDA queries) |
| -1 | KEDA, Karpenter, NVIDIA device plugin |
| 0 | llm-operator |
| 1 | gateway, which mounts the config the operator writes |
| 2 | inference: NodePool, EC2NodeClass, LLMDeployments |

The operator needs the base config to write the merged one, and the gateway
needs the merged one to start. That is not a deadlock: the operator watches
the base ConfigMap, so it writes the merged config seconds after the gateway
app creates the base, and the gateway's pods start then.

## Consequences

- With every model scaled to zero, the GPU cost is zero. The first request
  after a quiet spell waits for a node (about 2 to 3 minutes); the gateway
  answers from the hosted model meanwhile, except for personal data, which
  gets a 503 until the pool is up. inference-autoscaler's ADR 2 has the
  numbers and the alternatives.
- The NodePool caps the pool at 4 GPUs, so a runaway scale-up has a ceiling.
- Three more controllers to upgrade: KEDA, Karpenter and the device plugin.
  Renovate tracks their chart versions with the others.
- Not yet applied to a real account. CI renders and validates every new
  manifest with the switch on, and Terraform validates, but the first apply
  is the real test, starting in dev.
