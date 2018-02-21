# 安裝與設定 Calico Network

- [前言]()
- [建立 Calico controller]()
- [下載 Calico CLI]()
- [下載 Calico]()
- []()

## 前言
https://github.com/projectcalico/calico
https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/hosted

## 建立 Calico controller
> On master

ref: https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/rbac.yaml  
https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/calico.yaml  

```
$ mkdir -p /etc/kubernetes/network && cd /etc/kubernetes/network
$ calico.yaml
```
```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: calico-kube-controllers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: calico-kube-controllers
subjects:
- kind: ServiceAccount
  name: calico-kube-controllers
  namespace: kube-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: calico-kube-controllers
  namespace: kube-system
rules:
  - apiGroups:
    - ""
    - extensions
    resources:
      - pods
      - namespaces
      - networkpolicies
    verbs:
      - watch
      - list
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: calico-kube-controllers
  namespace: kube-system
---

# This manifest deploys the Calico Kubernetes controllers.
# See https://github.com/projectcalico/kube-controllers
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: calico-kube-controllers
  namespace: kube-system
  labels:
    k8s-app: calico-kube-controllers
spec:
  # The controllers can only have a single active instance.
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      name: calico-kube-controllers
      namespace: kube-system
      labels:
        k8s-app: calico-kube-controllers
    spec:
      hostNetwork: true
      serviceAccountName: calico-kube-controllers
      containers:
      - name: calico-kube-controllers
        image: quay.io/calico/kube-controllers:v2.0.0
        env:
          - name: ETCD_ENDPOINTS
            value: "https://10.140.0.2:2379"
          - name: ETCD_CA_CERT_FILE
            value: "/etc/etcd/ssl/etcd-ca.pem"
          - name: ETCD_CERT_FILE
            value: "/etc/etcd/ssl/etcd.pem"
          - name: ETCD_KEY_FILE
            value: "/etc/etcd/ssl/etcd-key.pem"
        volumeMounts:
          - mountPath: /etc/etcd/ssl
            name: etcd-ca-certs
            readOnly: true
      volumes:
        - hostPath:
            path: /etc/etcd/ssl
            type: DirectoryOrCreate
          name: etcd-ca-certs
```
```sh
$ kubectl apply -f calico.yaml
$ kubectl -n kube-system get po -l k8s-app=calico-kube-controllers
NAME                                       READY     STATUS    RESTARTS   AGE
calico-kube-controllers-64b458b8d6-dfglq   0/1       Pending   0          8s
```

## 下載 Calico CLI
> On master

```sh
$ cd && wget https://github.com/projectcalico/calicoctl/releases/download/v2.0.0/calicoctl
$ chmod +x calicoctl && mv calicoctl /usr/local/bin/
```

## 下載 Calico
> All nodes

```sh
$ wget -N -P /opt/cni/bin https://github.com/projectcalico/cni-plugin/releases/download/v2.0.0/calico
$ wget -N -P /opt/cni/bin https://github.com/projectcalico/cni-plugin/releases/download/v2.0.0/calico-ipam
$ chmod +x /opt/cni/bin/calico /opt/cni/bin/calico-ipam
```

## 設定 calico-node.service
> All nodes
```sh
$ mkdir -p /etc/cni/net.d
```

```sh
$ vim /etc/cni/net.d/10-calico.conf
```
```
{
    "name": "calico-k8s-network",
    "cniVersion": "0.1.0",
    "type": "calico",
    "etcd_endpoints": "https://10.140.0.2:2379",
    "etcd_ca_cert_file": "/etc/etcd/ssl/etcd-ca.pem",
    "etcd_cert_file": "/etc/etcd/ssl/etcd.pem",
    "etcd_key_file": "/etc/etcd/ssl/etcd-key.pem",
    "log_level": "info",
    "ipam": {
        "type": "calico-ipam"
    },
    "policy": {
        "type": "k8s"
    },
    "kubernetes": {
        "kubeconfig": "/etc/kubernetes/kubelet.conf"
    }
}
```
```sh
$ vim /lib/systemd/system/calico-node.service
```
```yaml
[Unit]
Description=calico node
After=docker.service
Requires=docker.service

[Service]
User=root
PermissionsStartOnly=true
ExecStart=/usr/bin/docker run --net=host --privileged --name=calico-node \
  -e ETCD_ENDPOINTS=https://10.140.0.2:2379 \
  -e ETCD_CA_CERT_FILE=/etc/etcd/ssl/etcd-ca.pem \
  -e ETCD_CERT_FILE=/etc/etcd/ssl/etcd.pem \
  -e ETCD_KEY_FILE=/etc/etcd/ssl/etcd-key.pem \
  -e NODENAME=${HOSTNAME} \
  -e IP= \
  -e NO_DEFAULT_POOLS= \
  -e AS= \
  -e CALICO_LIBNETWORK_ENABLED=true \
  -e IP6= \
  -e CALICO_NETWORKING_BACKEND=bird \
  -e FELIX_DEFAULTENDPOINTTOHOSTACTION=ACCEPT \
  -e FELIX_HEALTHENABLED=true \
  -e CALICO_IPV4POOL_CIDR=10.244.0.0/16 \
  -e CALICO_IPV4POOL_IPIP=always \
  -e IP_AUTODETECTION_METHOD=interface=ens4 \
  -e IP6_AUTODETECTION_METHOD=interface=ens4 \
  -v /etc/etcd/ssl:/etc/etcd/ssl \
  -v /var/run/calico:/var/run/calico \
  -v /lib/modules:/lib/modules \
  -v /run/docker/plugins:/run/docker/plugins \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/log/calico:/var/log/calico \
  quay.io/calico/node:v3.0.2
ExecStop=/usr/bin/docker rm -f calico-node
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```
Memo: IP_AUTODETECTION_METHOD 需使用 ifconfig 查看網卡名稱

## 啟動 Calico-node
> All nodes
```sh
$ systemctl enable calico-node.service && systemctl start calico-node.service
```

## 驗證
> master1 node

- 查看 Calico nodes
```sh
$ cat <<EOF > ~/calico-rc
export ETCD_ENDPOINTS="https://10.140.0.2:2379"
export ETCD_CA_CERT_FILE="/etc/etcd/ssl/etcd-ca.pem"
export ETCD_CERT_FILE="/etc/etcd/ssl/etcd.pem"
export ETCD_KEY_FILE="/etc/etcd/ssl/etcd-key.pem"
EOF

$ . ~/calico-rc
$ calicoctl get node -o wide
```

- 查看 pod
```sh
$ kubectl -n kube-system get po
NAME                                       READY     STATUS    RESTARTS   AGE
calico-kube-controllers-64b458b8d6-dfglq   1/1       Running   0          20m
```
