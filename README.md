## Rancher Fleet - Kubernetes + GitOps

All images and charts that Carbide provides come from `registry.ranchercarbide.dev` (`*-values-carbide.yaml`). Charts from the Carbide OCI registry (`oci://registry.ranchercarbide.dev/...`) are pulled with a `registry-creds` basic-auth secret (Carbide registry username and password), which must exist in both `fleet-local` and `fleet-default`.

## Deployment Instructions

- Apply both the Fleet GitRepo commands from below to the `local` cluster. I find it easiest to use the kubectl shell inside of the Rancher Manager.
- Add a Cluster Label to each cluster: **Rancher Manager UI -> Hamburger Menu -> Continuous Delivery -> Clusters -> Select Cluster & Edit Labels**

| Label | Installs | Rancher (`local`) | Downstream | Notes |
|---|---|---|---|---|
| **RGS Carbide** | | | | |
| `carbide=enabled` | Compliance and STIG profiles: `rancher-compliance`, `rancher-compliance-crd`, `rgs-stig-profiles`, `airgapped-docs` | ✅ | ✅ | `airgapped-docs` is `local` only |
| `ui-extensions=enabled` | RGS UI Plugin Catalog: `ui-plugin-catalog` | ✅ |  |  |
| `<name>-ui-extension=enabled` | One UI extension from the catalog: `capa`, `elemental`, `harvester`, `admission-controller` (or `kubewarden`), `neuvector`, `observability`, `rancher-ai`, `supportability-review`, `virtual-clusters`, or `vulnerability-scanner` | ✅ |  | Needs `ui-extensions=enabled` |
| **RGS Security** | | | | |
| `admission-controller=enabled` | RGS Security Admission Controller: `admission-controller`, with Policy Reporter | ✅ | ✅ | Use this or `kubewarden=enabled`, not both |
| `vulnerability-scanner=enabled` | RGS Security Vulnerability Scanner: `vulnerability-scanner`, plus `cloudnative-pg` | ✅ | ✅ | Needs `cert-manager` |
| `runtime-enforcer=enabled` | RGS Security Runtime Enforcer: `runtime-enforcer`, plus `cert-manager-csi-driver` | ✅ | ✅ | Needs `cert-manager` |
| **RGS Storage** | | | | |
| `longhorn=enabled` | Longhorn: `longhorn`, `longhorn-crd`, `longhorn-configs` | ✅ | ✅ | Default storage class |
| `longhorn-v2=enabled` | Longhorn V2 Data Engine: switches `longhorn` and `longhorn-encrypted` to v2 and turns off v1 | ✅ | ✅ | Needs `longhorn=enabled`, plus 2 GiB of hugepages, the `vfio_pci`, `uio_pci_generic`, and `nvme_tcp` modules, and raw block disks on each node, registered with the `node.longhorn.io/default-disks-config` annotation |
| **RGS AI Stack** | | | | |
| `ai-cluster=enabled` | AI cluster: `ai-cluster`, which builds a downstream cluster from `rancher-cluster-templates` | ✅ |  | Needs the `ai-cluster-config` and `ai-cluster-values` secrets in `fleet-default` |
| `gpu-operator=enabled` | NVIDIA GPU Operator: `gpu-operator` | | ✅ | Leave it off on a cluster that already runs the GPU Operator |
| `open-webui=enabled` | Open WebUI: `open-webui`, with Apache Tika and the Chat link in the cluster's Rancher dashboard. No model backend until the values set one | | ✅ | Needs the `open-webui-values` secret (key `values.yaml`, `{}` for none) in `open-webui` for the model backend, branding, and anything cluster-specific, and the `open-webui-tls` secret for the `ai-webui-host` cluster label's ingress |
| `open-webui-mcpo=enabled` | Open WebUI mcpo: `open-webui-mcpo`, which serves MCP servers that run as a local command as OpenAPI tool servers for Open WebUI, each at `http://open-webui-mcpo.open-webui-mcpo.svc:8000/<name>`. Ships with no servers | | ✅ | Needs the `open-webui-mcpo-values` secret (key `values.yaml`) in `open-webui-mcpo` with at least one server under `config.mcpServers`, since mcpo won't start without one. Servers started with `npx` or `uvx` download at startup, so an airgap needs them packaged ahead of time or a local npm and PyPI mirror |
| `vllm=enabled` | vLLM: `vllm`, one release per GPU node | | ✅ | Needs `gpu-operator=enabled` and the `vllm-values` secret (key `values.yaml`) in `vllm`. Downloads its model from Hugging Face unless the values point it at local files |
| `litellm=enabled` | LiteLLM: `litellm`, an OpenAI compatible gateway | | ✅ | Needs the `ai-litellm` secret and `ai-litellm-models` ConfigMap in `litellm` |
| `milvus=enabled` | Milvus: `milvus`, a vector database for Open WebUI's document search | | ✅ |  |
| `ai-monitoring=enabled` | AI dashboards: `ai-monitoring`, the NVIDIA DCGM and vLLM dashboards and the vLLM ServiceMonitor | | ✅ | Needs `monitoring=enabled` |
| `ollama=enabled` | Ollama: `ollama`, one release per GPU node (`gpu-0` to `gpu-2`), as an alternative to `vllm` | | ✅ | Needs `gpu-operator=enabled` and GPU nodes labeled `rgs.ai/gpu=nvidia`. Add Ollama as a connection in Open WebUI |
| `kserve=enabled` | KServe and vLLM: `kserve-crd`, `kserve` (Standard mode, no Knative or Istio), and `ai-models` (the RGS vLLM OpenAI image as a ServingRuntime, one InferenceService per model, and with `monitoring=enabled` a PodMonitor for the `ai-monitoring` vLLM dashboards). Replaces `vllm` on the same cluster | | ✅ | Needs `cert-manager` and the `ai-models-values` secret (key `values.yaml`) in `ai-models`, which lists the models and the S3 buckets that hold them. Each model is reached at `http://<name>-predictor.ai-models.svc.cluster.local/v1` |
| `egress-gateway=enabled` | AI Egress Gateway: `egress-gateway` (a separate Traefik that never registers as an ingress) and `egress-routes` (the allowed sites, the AI's own client certificate, and network policies so the listed namespaces leave the cluster only through the gateway). Every outbound call is in the gateway's access log | | ✅ | Needs `cert-manager`, the `egress-gateway-values` secret with a fixed `service.spec.clusterIP`, and the `egress-routes-values` secret, both in `egress-gateway` (examples in [`fleet/egress-routes/examples/`](fleet/egress-routes/examples/)). Each locked app needs `hostAliases` pointing its allowed sites at that IP and must trust the gateway CA, such as Open WebUI mounting an `egress-gateway-ca` ConfigMap through its values |
| `agentgateway=enabled` | agentgateway: `agentgateway-crds` and `agentgateway`, the controller for the `agentgateway` GatewayClass, which serves models (local and Amazon Bedrock) behind one OpenAI compatible endpoint and fronts MCP servers | | ✅ | Needs the Gateway API standard CRDs, which RKE2's Traefik installs from v1.36. The Gateway, models, and API keys come from the cluster's own manifests. In an airgap, mirror `cr.agentgateway.dev` in `registries.yaml`, since the controller creates each proxy with that registry |
| `rancher-ai=enabled` | RGS AI Integrations: the `rancher-ai` UI extension (Liz, the RGS AI Assistant), `rancher-ai-agent` (the RGS AI Agent and RGS MCP Server behind it), and `rancher-ai-ui-tools` (Liz's UI tools, turned on) | ✅ |  | Needs `ui-extensions=enabled` and the `rancher-ai-agent-values` secret in `fleet-local`. Uses LiteLLM on the AI cluster at `https://<ai-webui-host>/v1` through the agent's `openai` provider |
| **RGS HobbyFarm** | | | | |
| `hobbyfarm=enabled` | HobbyFarm: `hobbyfarm` (the HobbyFarm chart with the RGS Learn branding) and `hobbyfarm-configs` (the Environment, VM Templates, Users, TLS Certificate, and the Student and Admin links in that cluster's Rancher dashboard) | ✅ | ✅ | Needs the `hobbyfarm-values`, `hobbyfarm-configs-values`, and `aws-creds` secrets in `hobbyfarm-system`, which [zackbradys/hobbyfarm](https://github.com/zackbradys/hobbyfarm) creates, and the `letsencrypt-production` ClusterIssuer (on `local` from the Rancher install). The scenarios and courses come from that repo too |
| **Platform Apps** | | | | |
| `cert-manager=enabled` | cert-manager: `cert-manager` | ✅ | ✅ | The `local` cluster usually has `cert-manager` from Rancher's install |
| `cert-manager-csi-driver=enabled` | cert-manager CSI driver: `cert-manager-csi-driver` | ✅ | ✅ | Also installed by `runtime-enforcer=enabled` |
| `monitoring=enabled` | Monitoring: `kube-prometheus-stack`, `rancher-monitoring-dashboards`, `monitoring-configs` (lets Prometheus reach the CoreDNS metrics under RKE2's CIS network policies) | ✅ | ✅ | `rancher-monitoring` is deprecated in Rancher 2.15 |
| `logging=enabled` | Logging: `rancher-logging`, `rancher-logging-crd` | ✅ | ✅ |  |
| `neuvector=enabled` | NeuVector: `neuvector`, `neuvector-crd` | ✅ | ✅ |  |
| `kubewarden=enabled` | Kubewarden: `kubewarden` (the open source `admission-controller` chart with RGS Carbide images), with Policy Reporter | ✅ | ✅ | Use this or `admission-controller=enabled`, not both. The Policy Reporter page needs `admission-controller` |
| `cloudnative-pg=enabled` | CloudNativePG operator: `cloudnative-pg` | ✅ | ✅ | Also installed by `vulnerability-scanner=enabled` |


## Fleet Local and Fleet Default

```bash
# Adds the GitRepo(s) for use within the local cluster
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/fleet-resources-local.yaml

# Adds the GitRepo(s) for use with all downstream cluster(s)
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/fleet-resources-default.yaml
```

## Airgap With Hauler

Each bundle directory has a `hauler-<name>-manifest.yaml` with its chart and every image it pulls, and a `.fleetignore` that keeps Fleet from applying it. The UI extensions have none, since their charts ship inside the `ui-plugin-catalog` image.

```bash
# login to the carbide registry
hauler login registry.ranchercarbide.dev --username <username> --password <password>

# builds one store from every bundle manifest
hauler store sync -p linux/amd64 $(find fleet -name 'hauler-*-manifest.yaml' -exec printf -- '-f %s ' {} \;)
```

Leave off `--registry`, because it overrides the `hauler.dev/registry` annotation that points the Carbide charts' image lists at `registry.ranchercarbide.dev`.

## Carbide Without Fleet (Optional)

Shell helpers that install the same Carbide pieces with `helm`/`kubectl` are in [`shell/`](shell/README.md)

## Fleet Deployment Architecture Diagram

![fleet-architecture-diagram](https://fleet.rancher.io/_images/fleet-architecture.svg)
