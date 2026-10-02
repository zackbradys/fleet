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

### Add Classification Banners
kubectl apply -f - <<EOF
apiVersion: management.cattle.io/v3
customized: false
default: '{}'
kind: Setting
metadata:
  name: ui-banners
value: '{"loginError":{"message":"","showMessage":"false"},"bannerHeader":{"background":"#007a33","color":"#ffffff","textAlignment":"center","fontSize":"14px","text":"UNCLASSIFIED"},"bannerFooter":{"background":"#007a33","color":"#ffffff","textAlignment":"center","fontSize":"14px","text":"UNCLASSIFIED"},"bannerConsent":{"background":"#eeeff4","color":"#141419","button":"Accept","html":"<div
  style=\"font-size:24px;line-height:2.0;text-align:center;\">\n  <p style=\"margin:0
  0 12px 0;\"><strong>DoD Warning and Consent Banner</strong></p>\n</div>\n<div style=\"font-size:14px;line-height:1.6;text-align:center;\">\n  <p
  style=\"margin:0 0 12px 0;\"><strong>You are accessing a U.S. Government (USG) Information
  System (IS) that is provided for USG-authorized use only. By using this IS (which
  includes any device attached to this IS), you consent to the following conditions:</strong></p>\n  <p
  style=\"margin:0 0 12px 0;\">The USG routinely intercepts and monitors communications
  on this IS for purposes including, but not limited to, penetration testing, COMSEC
  monitoring, network operations and defense, personnel misconduct (PM), law enforcement
  (LE), and counterintelligence (CI) investigations.</p>\n  <p style=\"margin:0 0
  12px 0;\">At any time, the USG may inspect and seize data stored on this IS.</p>\n  <p
  style=\"margin:0 0 12px 0;\">Communications using, or data stored on, this IS are
  not private, are subject to routine monitoring, interception, and search, and may
  be disclosed or used for any USG authorized purpose.</p>\n  <p style=\"margin:0
  0 12px 0;\">This IS includes security measures (e.g., authentication and access
  controls) to protect USG interests--not for your personal benefit or privacy.</p>\n  <p
  style=\"margin:0 0 12px 0;\">Notwithstanding the above, using this IS does not constitute
  consent to PM, LE or CI investigative searching or monitoring of the content of
  privileged communications, or work product, related to personal representation or
  services by attorneys, psychotherapists, or clergy, and their assistants. Such communications
  and work product are private and confidential.</p>\n  <p style=\"margin:0 0 12px
  0;\">See User Agreement for details.</p>\n</div>"},"showHeader":"true","showFooter":"true","showConsent":"true"}'
EOF

### Add Rancher Chart Repo
helm repo add rancher-charts https://charts.rancher.io
helm repo update

### Install Compliance Operator
kubectl create namespace compliance-operator-system

kubectl label namespace compliance-operator-system pod-security.kubernetes.io/audit=privileged pod-security.kubernetes.io/audit-version=latest pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/enforce-version=latest pod-security.kubernetes.io/warn=privileged pod-security.kubernetes.io/warn-version=latest

helm upgrade -i rancher-compliance-crd rancher-charts/rancher-compliance-crd -n compliance-operator-system --version=110.2.0+up1.5.3 --set global.cattle.url=https://rancher.$DOMAIN --set global.cattle.systemDefaultRegistry=$CarbideRegistry

sleep 10

helm upgrade -i rancher-compliance rancher-charts/rancher-compliance -n compliance-operator-system --version=110.2.0+up1.5.3 --set global.cattle.url=https://rancher.$DOMAIN --set global.cattle.systemDefaultRegistry=$CarbideRegistry

sleep 30

### Install Carbide Applications
kubectl create namespace carbide-docs-system

helm repo add carbide-charts https://rancherfederal.github.io/carbide-charts
helm repo add kubewarden https://charts.kubewarden.io
helm repo update

### vdb-explorer disabled until the chart provides a writable /var/lib/vuldb (see fleet/airgapped-docs)
helm upgrade -i airgapped-docs carbide-charts/airgapped-docs -n carbide-docs-system --version=0.1.56 --set global.cattle.systemDefaultRegistry=$CarbideRegistry --set docs.neuvectorvdbexplorer.enabled=false

### Install UI Extensions
