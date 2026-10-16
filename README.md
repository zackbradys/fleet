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
| `ai=enabled` | On `local`: `ai-cluster`, which builds the AI cluster. On the AI cluster: `gpu-operator`, `cloudnative-pg`, `milvus`, `vllm`, `litellm`, `open-webui` | ✅ | ✅ | Needs the `vllm-values` and `open-webui-values` secrets (key `values.yaml`, `{}` for none) in the `vllm` and `open-webui` namespaces, for anything cluster-specific like air-gapped model files |
| `ollama=enabled` | Ollama: `ollama`, one release per GPU node (`gpu-0` to `gpu-2`), as an alternative to `vllm` | | ✅ | Needs GPU nodes labeled `rgs.ai/gpu=nvidia`. Open WebUI connects to `vllm` through LiteLLM, so add Ollama as a connection in Open WebUI |
| `rancher-ai=enabled` | RGS AI Integrations: the `rancher-ai` UI extension (Liz, the RGS AI Assistant), `rancher-ai-agent` (the RGS AI Agent and RGS MCP Server behind it), and `rancher-ai-ui-tools` (Liz's UI tools, turned on) | ✅ |  | Needs `ui-extensions=enabled` and the `rancher-ai-agent-values` secret in `fleet-local`. Uses LiteLLM on the AI cluster at `https://<ai-webui-host>/v1` through the agent's `openai` provider |
| **Platform Apps** | | | | |
| `cert-manager=enabled` | cert-manager: `cert-manager` | ✅ | ✅ | The `local` cluster usually has `cert-manager` from Rancher's install |
| `cert-manager-csi-driver=enabled` | cert-manager CSI driver: `cert-manager-csi-driver` | ✅ | ✅ | Also installed by `runtime-enforcer=enabled` |
| `monitoring=enabled` | Monitoring: `kube-prometheus-stack`, `rancher-monitoring-dashboards` | ✅ | ✅ | `rancher-monitoring` is deprecated in Rancher 2.15 |
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

## Carbide Without Fleet (Optional)

Shell helpers that install the same Carbide pieces with `helm`/`kubectl` are in [`shell/`](shell/README.md)

## Fleet Deployment Architecture Diagram

![fleet-architecture-diagram](https://fleet.rancher.io/_images/fleet-architecture.svg)
