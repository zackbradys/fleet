## Rancher Fleet - Kubernetes + GitOps

### Deployment Instructions

- Apply both the Fleet GitRepo commands from below to the `local` cluster. I find it easiest to use the kubectl shell inside of the Rancher Manager.
- Add a Cluster Label to each cluster: **Rancher Manager UI -> Hamburger Menu -> Continuous Delivery -> Clusters -> Select Cluster & Edit Labels**
  - For Rancher Longhorn, use the label: `longhorn=enabled`
  - For Rancher NeuVector, use the label: `neuvector=enabled`
  - For Rancher Monitoring, use the label: `monitoring=enabled`
  - For Rancher Logging, use the label: `monitoring=enabled`
  - For Rancher KubeWarden, use the label: `kubewarden=enabled`

### Fleet Local and Fleet Default

```bash
### Adds the GitRepo(s) to the local cluster.
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/gitrepo-local.yaml

### Adds the GitRepo(s) to all downstream cluster(s).
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/gitrepo-default.yaml
```

### Fleet Deployment Architecture Diagram

![fleet-architecture-diagram](https://fleet.rancher.io/assets/images/fleet-architecture-f708ce634648101dc98f451dcd59fe84.svg)
