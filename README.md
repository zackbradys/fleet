## Rancher Fleet - Kubernetes + GitOps

### Deployment Instructions
* Apply the Fleet GitRepo commands from below to the `local` cluster. I find it easiest to use the kubectl shell inside of the Rancher Manager.
* Add a Cluster Label to each cluster. `Rancher Manager -> Continuous Delivery -> Clusters -> Select Cluster & Edit Labels
  * For Rancher Longhorn, use the label: `longhorn=enabled`
  * For Rancher NeuVector, use the label: `neuvector=enabled`
  * For Rancher Monitoring, use the label: `monitoring=enabled`

### Fleet Local
```bash
### Adds the GitRepo to the local cluster.
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/gitrepo-local.yaml
```

### Fleet Default
```bash
### Adds the GitRepo to all downstream cluster(s).
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/gitrepo-default.yaml
```