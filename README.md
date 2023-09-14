## Rancher Fleet - Kubernetes x GitOps

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