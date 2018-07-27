# CoreDNS 初認識

> https://kubernetes.io/docs/tasks/administer-cluster/coredns/  
> https://kubernetes.io/blog/2018/07/10/coredns-ga-for-kubernetes-cluster-dns/  

要使用 CoreDNS ，kubernetes 版本必須要在 v1.9 以上。  
就連在 Kubernetes v1.11，CoreDNS 已經是 kubeadm 的 default 安裝。  

## CoreDNS Manual

> https://coredns.io/manual/toc/  

### 介紹

- CoreDNS 和其他的 DNS servers (如: BIND)不一樣， CoreDNS 非常的彈性靈活， chains plugins。
- Plugin 可以自己存在，也可以共同一起 work ，執行它的 DNS 功能(DNS function)。
- DNS function 是個軟體，實現 CoreDNS Plugin API
- CoreDNS 的 default 安裝包含大約 30 個 plugin，也可以有 external plugins

### 安裝
有 4 種安裝方式  
- Binaries
- [Docker](https://hub.docker.com/r/coredns/coredns/) - 之後在 k8s 上以 deployment 來測試(To becontinue)。
- Source
- Source from Github


