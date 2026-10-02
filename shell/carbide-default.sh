### Add Rancher Extensions Chart Repo
kubectl apply -f - <<EOF
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: rancher-extensions
spec:
  gitBranch: main
  gitRepo: https://github.com/rancher/ui-plugin-charts
EOF

### Add Rancher Partner Extensions Chart Repo
kubectl apply -f - <<EOF
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: rancher-partner-extensions
spec:
  gitBranch: main
  gitRepo: https://github.com/rancher/partner-extensions
EOF

### Add Rancher Government Carbide Chart Repo
kubectl apply -f - <<EOF
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: carbide-charts
spec:
  gitBranch: main
  gitRepo: https://github.com/rancherfederal/carbide-charts
EOF

### Add Rancher Chart Repo
helm repo add rancher-charts https://charts.rancher.io
helm repo update

### Install Carbide Applications
helm repo add carbide-charts https://rancherfederal.github.io/carbide-charts
helm repo add kubewarden https://charts.kubewarden.io
helm repo update
