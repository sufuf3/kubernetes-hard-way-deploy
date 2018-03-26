# Summary

* [README](README.md)

## 純手動安裝

* [01. Node 架構與準備](deploy1.8/01-prerequisites.md)
* [02. 部署 etcd](deploy1.8/02-bootstrapping-etcd.md)
* [03. 部署 Kubernetes Master](deploy1.8/03-bootstrapping-master.md)
* [03. 部署 Kubernetes Node](deploy1.8/04-bootstrapping-node.md)
* [05. Kubernetes Node 授權](deploy1.8/05-node-csr.md)
* [06. Kube-proxy 部署](deploy1.8/06-Kube-proxy.md)
* [07. Kube-dns 部署](deploy1.8/07-Kube-dns.md)
* [08. 安裝與設定 Calico Network](deploy1.8/08-network.md)
* [09. Dashboard](deploy1.8/09-dashboard.md)
* [10. play with container](deploy1.8/10-play-with-container.md)

## 核心原理

## Objects
* [Ingress](objects/ingress.md)
* [Service]()
    * Service Type - [NodePort](objects/setviceTypes.md)
    * Service Type - [LoadBalancer](objects/setviceTypes.md)
    * Service Type - [ClusterIP](objects/setviceTypes.md)

## 核心元件
* [kubectl](component/core)
* [kube-apiserver](component/core)
* [kube-scheduler](component/core)
* [kube-controller-manager](component/core)

## 其他元件

* [etcd](concept/etcd.md)

## 網路
* [Calico](concept/network/calico.md)
