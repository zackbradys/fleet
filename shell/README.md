# Carbide Without Fleet

### Deployment Options

These scripts install the Carbide pieces with `helm` and `kubectl`, with `carbide-local.sh` for the `local` cluster and `carbide-default.sh` for each downstream cluster.

* Configure each cluster for the Carbide registry first, as in the [Carbide registry docs](https://docs.ranchercarbide.dev/docs/registry-docs/introduction).
* Set `DOMAIN` and `CarbideRegistry`, then download and run the script against that cluster.

### Carbide Local Script
```bash
### Set Script Variables
export DOMAIN=domain.url
export CarbideRegistry=registry.url

### Run the Carbide Local Script
curl -#OL https://raw.githubusercontent.com/zackbradys/fleet/main/shell/carbide-local.sh
bash carbide-local.sh
```

### Carbide Default Script
```bash
### Set Script Variables
export DOMAIN=domain.url
export CarbideRegistry=registry.url

### Run the Carbide Default Script
curl -#OL https://raw.githubusercontent.com/zackbradys/fleet/main/shell/carbide-default.sh
bash carbide-default.sh
```
