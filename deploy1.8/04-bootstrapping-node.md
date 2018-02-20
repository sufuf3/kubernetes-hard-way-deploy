# Kubernetes Node 安裝

## Table of Contents
- [前言]()
- [從 Master 複製 key 到 node]()
- [下載 kubelet & CNI]()
- [設定kubelet]()

## 前言
以下皆在 node 進行 (B&C)

## 從 Master 複製 key 到 node
- 創建路徑
```
$ mkdir -p /etc/kubernetes/ssl
$ mkdir -p /etc/etcd/ssl
```
- 複製 Etcd 的 key
`etcd-ca.pem etcd.pem etcd-key.pem` 到 `/etc/etcd/ssl/`

- 複製 kubernetes 的 key
`ssl/ca.pem ssl/ca-key.pem bootstrap.conf` 到 `/etc/kubernetes`

## 下載 kubelet & CNI
- 下載與安裝 kubelet

```sh
$ wget -q --show-progress --https-only --timestamping "https://storage.googleapis.com/kubernetes-release/release/v1.8.8/bin/linux/amd64/kubelet" -O /usr/local/bin/kubelet
$ chmod +x /usr/local/bin/kubelet
```
- 下載 CNI
```sh
$ mkdir -p /opt/cni/bin && cd /opt/cni/bin
$ wget -qO- --show-progress "https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz" | tar -zx
```

## 設定 kubelet

```sh
$ mkdir -p /etc/systemd/system/kubelet.service.d
```

```sh
$ vim /lib/systemd/system/kubelet.service
```
```yaml
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]
ExecStart=/usr/local/bin/kubelet
Restart=on-failure
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```sh
$ vim /etc/systemd/system/kubelet.service.d/10-kubelet.conf
```
```yaml
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--address=0.0.0.0 --port=10250 --kubeconfig=/etc/kubernetes/kubelet.conf --bootstrap-kubeconfig=/etc/kubernetes/bootstrap.conf"
Environment="KUBE_LOGTOSTDERR=--logtostderr=true --v=0"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true --anonymous-auth=false"
Environment="KUBELET_POD_CONTAINER=--pod-infra-container-image=gcr.io/google_containers/pause:3.0"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/ssl/ca.pem"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/ssl"
Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false --serialize-image-pulls=false"
Environment="KUBE_NODE_LABEL=--node-labels=node-role.kubernetes.io/node=true"
ExecStart=
ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBE_LOGTOSTDERR $KUBELET_POD_CONTAINER $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_EXTRA_ARGS $KUBE_NODE_LABEL
```
- 建立 var 存放資訊 & 啟動 kubelet
```sh
$ mkdir -p /var/lib/kubelet /var/log/kubernetes /etc/kubernetes/manifests
$ systemctl enable kubelet.service && systemctl start kubelet.service
```
