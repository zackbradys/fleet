## Rancher Fleet - Kubernetes + GitOps

### Deployment Instructions

- Apply both the Fleet GitRepo commands from below to the `local` cluster. I find it easiest to use the kubectl shell inside of the Rancher Manager.
- Add a Cluster Label to each cluster: **Rancher Manager UI -> Hamburger Menu -> Continuous Delivery -> Clusters -> Select Cluster & Edit Labels**
  - For Rancher Longhorn, use the label: `longhorn=enabled`
  - For Rancher NeuVector, use the label: `neuvector=enabled`
  - For Rancher Monitoring, use the label: `monitoring=enabled` (kube-prometheus-stack + rancher-monitoring-dashboards; `rancher-monitoring` is deprecated in Rancher 2.15)
  - For Rancher Logging, use the label: `logging=enabled`
  - For Rancher KubeWarden, use the label: `kubewarden=enabled`
  - For Rancher Government Carbide, use the label: `carbide=enabled` (compliance + RGS STIG profiles on every cluster, plus the airgapped docs on the `local` cluster)
  - For the RGS UI Plugin Catalog (the airgapped UI extensions catalog), use the label: `ui-extensions=enabled` (`local` cluster)
  - For each UI extension from that catalog, also add its label (`local` cluster): `capa-ui-extension`, `elemental-ui-extension`, `harvester-ui-extension`, `kubewarden-ui-extension`, `neuvector-ui-extension`, `observability-ui-extension`, `rancher-ai-ui-extension`, `supportability-review-ui-extension`, `virtual-clusters-ui-extension`, or `vulnerability-scanner-ui-extension` `=enabled`
  - For the RGS AI Stack, use the label: `ai=enabled` (`local` cluster, see [RGS AI Stack](#rgs-ai-stack))

All images and charts that Carbide provides come from `registry.ranchercarbide.dev` (`*-values-carbide.yaml`). The RGS STIG profiles chart is pulled with a `registry-creds` basic-auth secret (Carbide registry username and password), which must exist in both `fleet-local` and `fleet-default`. Clusters must be configured for the Carbide registry ([docs](https://rancherfederal.github.io/carbide-docs/docs/registry-docs/kubernetes-config)).

### Fleet Local and Fleet Default

```bash
### Adds the GitRepo(s) to the local cluster.
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/fleet-resources-local.yaml

### Adds the GitRepo(s) to all downstream cluster(s).
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/fleet-resources-default.yaml
```

### RGS AI Stack

Labeling the `local` cluster `ai=enabled` makes Rancher build a GPU-backed AI cluster on AWS from the [Rancher cluster templates](https://github.com/RancherGovernment/rancher-cluster-templates). The new cluster is labeled `ai=enabled` too, so Fleet then deploys the AI stack onto it. Each app runs in its own namespace (`gpu-operator`, `cnpg-system`, `milvus`, `ollama`, `litellm`, and `open-webui`), set with its Pod Security label in its `fleet.yaml`. Fleet applies those labels after the first install, so on clusters that default to `rancher-restricted`, create the namespaces with their labels first.

| Bundle | What it deploys |
|---|---|
| `ai-cluster` | The downstream AI cluster, from the Rancher cluster templates chart. The cluster spec isn't in this repo; it comes from secrets (below) |
| `gpu-operator` | NVIDIA GPU Operator with precompiled drivers |
| `cloudnative-pg` | CloudNativePG, the PostgreSQL operator |
| `milvus` | Milvus, the vector database for document search |
| `ollama` | Ollama, one per GPU node, with `gpt-oss:120b` and `nomic-embed-text` |
| `litellm` | LiteLLM, the gateway to hosted models such as Amazon Bedrock. The model list comes from the environment (below) |
| `open-webui` | Open WebUI with Apache Tika, behind Traefik with a Let's Encrypt certificate |

The `ai-cluster` bundle has no values of its own. It reads two secrets that you create in `fleet-local` (key `values.yaml`), merged in this order:
1. **`ai-cluster-config`:** the cluster spec: RKE2 version and configuration, registries, Pod Security, the cluster labels that turn on the platform and AI bundles (including `ai=enabled`), and the addons.
2. **`ai-cluster-values`:** the environment:
   - **Node pools:** VPC, subnets, security group, AMI, IAM instance profile, and node userData.
   - **Cluster labels:** `ai-gpu-nodes`, `ai-webui-host`, and `ai-aws-region`.
   - **`additionalManifests`:** create each app's namespace with its Pod Security label, and the secrets the apps read: `ai-aws` (in `ollama`), `ai-litellm` (in `litellm`), and `ai-open-webui` (in `open-webui`), and the `ai-litellm-models` ConfigMap (in `litellm`, key `models.yaml`) with LiteLLM's `model_list`.

The bundle lists both secrets as `downstreamResources`: Fleet copies them into `fleet-default` for the chart, and watches them, so changing either one redeploys the cluster template.

Rancher also needs the `aws-creds` cloud credential in `cattle-global-data`, and the `registry-creds` secret.

The AI nodes' IAM instance profile needs:
- Amazon Bedrock, for LiteLLM
- Route53, for the Let's Encrypt DNS-01 challenge
- Read access to the S3 model cache, if one is used

The `rgs-ai-demo` repo provides both secrets and creates the AWS resources.

### Carbide Without Fleet (Optional)

Shell helpers that install the same Carbide pieces with `helm`/`kubectl` are in [`shell/`](shell/README.md).

### Fleet Deployment Architecture Diagram

![fleet-architecture-diagram](https://fleet.rancher.io/assets/images/fleet-architecture-f708ce634648101dc98f451dcd59fe84.svg)
