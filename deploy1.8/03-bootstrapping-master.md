# Kubernetes Master 安裝

## Table of Contents

- [前言]()
- [安裝 kubelet & kubectl元件]()
- [下載CNI]()
- [建立 CA 與 Certificates]()
  - [建立 CA 與 CA key]()
  - [建立 API server certificate]()
  - [建立 Front proxy certificate]()

## 前言
安裝以下元件
- kube-apiserver
- kube-scheduler
- kube-controller-manager

## 安裝 kubelet & kubectl 元件
- kubelet: 管 pod 用
- kubectl: 

- 下載與安裝 kubelet & kubectl
```sh
$ wget -q --show-progress --https-only --timestamping "https://storage.googleapis.com/kubernetes-release/release/v1.8.8/bin/linux/amd64/kubelet" -O /usr/local/bin/kubelet
$ wget -q --show-progress --https-only --timestamping "https://storage.googleapis.com/kubernetes-release/release/v1.8.8/bin/linux/amd64//kubectl" -O /usr/local/bin/kubectl
$ chmod +x /usr/local/bin/kubelet /usr/local/bin/kubectl
```

## 下載 CNI
```sh
$ mkdir -p /opt/cni/bin && cd /opt/cni/bin
$ wget -qO- --show-progress "https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz" | tar -zx
```
