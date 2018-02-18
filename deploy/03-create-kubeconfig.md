# 03. 建立 kubeconfig 文件

## Table of Contents
- [前言](#%E5%89%8D%E8%A8%80)
- [建立 kubectl kubeconfig 文件](#%E5%BB%BA%E7%AB%8B-kubectl-kubeconfig-%E6%96%87%E4%BB%B6)
- [建立 kube-proxy kubeconfig 文件](#%E5%BB%BA%E7%AB%8B-kube-proxy-kubeconfig-%E6%96%87%E4%BB%B6)

## 前言
在上一步已經建立好 kubelet 和 kube-proxy 的憑證和私鑰。  
而 kubeconfig 是 Kubernetes client 端和 API Server 認證的保證。  

## 建立 kubectl kubeconfig 文件
> 以下動作先在 A 進行，之後再複製到 D, E

```sh
$ export KUBE_APISERVER="https://10.140.0.2:6443"
$ cd /root/ssl

# 設置 cluster 的參數(worknode1)
kubectl config set-cluster kubernetes \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBE_APISERVER}:6443 \
  --kubeconfig=worknode1.kubeconfig

# 設置 cluster 的參數(worknode2)
kubectl config set-cluster kubernetes \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBE_APISERVER}:6443 \
  --kubeconfig=worknode2.kubeconfig

# 設定 client 端的認證參數 (worknode1)
kubectl config set-credentials system:node:worknode1 \
  --client-certificate=worknode1.pem \
  --embed-certs=true \
  --client-key=worknode1-key.pem \
  --kubeconfig=worknode1.kubeconfig

# 設定 client 端的認證參數 (worknode2)
kubectl config set-credentials system:node:worknode2 \
  --client-certificate=worknode2.pem \
  --embed-certs=true \
  --client-key=worknode2-key.pem \
  --kubeconfig=worknode2.kubeconfig

# 設置上下文參數(worknode1)
kubectl config set-context default \
  --cluster=kubernetes \
  --user=system:node:worknode1 \
  --kubeconfig=worknode1.kubeconfig

# 設置上下文參數(worknode2)
kubectl config set-context default \
  --cluster=kubernetes \
  --user=system:node:worknode2 \
  --kubeconfig=worknode2.kubeconfig

# 設置默認的上下文
kubectl config use-context default --kubeconfig=worknode1.kubeconfig
kubectl config use-context default --kubeconfig=worknode2.kubeconfig
```

- 將 worknode1.kubeconfig 複製到 D, worknode2.kubeconfig 複製到 E

## 建立 kube-proxy kubeconfig 文件
> 以下動作先在 A 進行，之後再複製到 D, E

```sh
$ cd /etc/kubernetes/ssl

# 設置 cluster 的參數
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

# 設定 client 端的認證參數 
kubectl config set-credentials kube-proxy \
  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

# 設置上下文參數
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

# 設置默認的上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

- 將 kube-proxy.kubeconfig 複製到 D, E
