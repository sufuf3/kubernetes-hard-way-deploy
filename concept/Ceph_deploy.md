# Deploy Ceph with Kubernetes
## Install 
Ref: http://docs.ceph.com/docs/master/start/kube-helm/
1. Install helm
```sh
$ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2690  100  2690    0     0   4986      0 --:--:-- --:--:-- --:--:--  4981
Error: cannot connect to Tiller
Helm v2.8.2 is available. Changing from version v2.7.2.
Downloading https://kubernetes-helm.storage.googleapis.com/helm-v2.8.2-linux-amd64.tar.gz
Preparing to install into /usr/local/bin
helm installed into /usr/local/bin/helm
Run 'helm init' to configure helm.
```
2. Run Tiller locally and connect Helm to it
```sh
$ helm init
Creating /root/.helm 
Creating /root/.helm/repository 
Creating /root/.helm/repository/cache 
Creating /root/.helm/repository/local 
Creating /root/.helm/plugins 
Creating /root/.helm/starters 
Creating /root/.helm/cache/archive 
Creating /root/.helm/repository/repositories.yaml 
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com 
Adding local repo with URL: http://127.0.0.1:8879/charts 
$HELM_HOME has been configured at /root/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```
3. Start a local Helm repo server
```sh
$ helm serve &
$ helm repo add local http://localhost:8879/charts
```
4. Add Ceph-helm to Helm local repos
```sh
$ cd ~/
$ git clone https://github.com/ceph/ceph-helm
$ cd ~/ceph-helm/ceph
$ make
```
5. Create a ceph-overrides.yaml that will contain your Ceph configuration.
```sh
$ vim ceph-overrides.yaml
```
```yaml
network:
  public:   10.244.0.0/16
  cluster:   10.244.0.0/16

osd_devices:
  - name: dev-sda
    device: /dev/sda
    zap: "1"

storageclass:
  name: ceph-rbd
  pool: rbd
  user_id: k8s
```
6. Deployment
```sh
$ kubectl create namespace ceph
$ kubectl create -f ~/ceph-helm/ceph/rbac.yaml
$ kubectl label nodes ceph-mon=enabled ceph-mgr=enabled ceph-osd=enabled ceph-osd-device-dev-sdb=enabled ceph-osd-device-dev-sdc=enabled ceph-rgw=enabled ceph-mds=enabled --all
$ cd ~/ceph-helm/
$ helm install --name=ceph local/ceph --namespace=ceph -f ceph-overrides.yaml
```

## Un-install
```sh
$ helm delete ceph --purge
```

## Troubleshooting
```sh
$ helm delete ceph --purge
Error: namespaces "ceph" is forbidden: User "system:serviceaccount:kube-system:default" cannot get namespaces in the namespace "ceph"

$ kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
clusterrolebinding "add-on-cluster-admin" created
```
```sh
$ helm delete ceph --purge
E0327 15:20:30.692015   16753 portforward.go:178] lost connection to pod
Error: transport is closing

$ helm ls --all
NAME    REVISION        UPDATED                         STATUS          CHART           NAMESPACE
ceph    1               Tue Mar 27 14:11:25 2018        DEPLOYED        ceph-0.1.0      ceph     

$ helm list
NAME    REVISION        UPDATED                         STATUS          CHART           NAMESPACE
ceph    1               Tue Mar 27 14:11:25 2018        DEPLOYED        ceph-0.1.0      ceph     

$ kubectl get cm --all-namespaces
NAMESPACE     NAME                                 DATA      AGE
kube-system   calico-config                        3         6h
kube-system   ceph.v1                              1         1h
kube-system   extension-apiserver-authentication   6         6h
kube-system   fluentd-es-config                    5         6h

$ kubectl delete cm ceph.v1 -n kube-system
configmap "ceph.v1" deleted
$ helm list
None
```
