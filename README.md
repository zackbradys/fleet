## Rancher Fleet - Kubernetes + GitOps


* Apply the Fleet GitRepo command to each of the `local` or `downstream` cluster(s). I prefer to use the kubectl shell inside of the Rancher Manager.
* Add a Cluster Label to each cluster. Once the Cluster Label is added to each cluster, Fleet will automatically deploy the resources.
  * For Rancher Longhorn, use the label: `longhorn=enabled`
  * For Rancher NeuVector, use the label: `neuvector=enabled`
  * For Rancher Monitoring, use the label: `monitoring=enabled`

### Fleet Local
```bash
### Deploys the app on the local cluster.
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/gitrepo-local.yaml
```

### Fleet Default
```bash
### Deploys the app to all downstream clusters.
kubectl apply -f https://raw.githubusercontent.com/zackbradys/fleet/main/gitrepo-default.yaml
```