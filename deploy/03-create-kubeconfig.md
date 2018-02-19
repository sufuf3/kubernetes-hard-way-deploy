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
$ export KUBE_APISERVER="10.140.0.2"
$ cd /etc/kubernetes/ssl

# 設置 cluster 的參數(worknode1)
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBE_APISERVER}:6443 \
    --kubeconfig=workernode1.kubeconfig

# 設置 cluster 的參數(worknode2)
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBE_APISERVER}:6443 \
    --kubeconfig=workernode2.kubeconfig

# 設定 client 端的認證參數 (worknode1)
  kubectl config set-credentials system:node:workernode1 \
    --client-certificate=workernode1.pem \
    --client-key=workernode1-key.pem \
    --embed-certs=true \
    --kubeconfig=workernode1.kubeconfig

# 設定 client 端的認證參數 (worknode2)
  kubectl config set-credentials system:node:workernode2 \
    --client-certificate=workernode2.pem \
    --client-key=workernode2-key.pem \
    --embed-certs=true \
    --kubeconfig=workernode2.kubeconfig

# 設置上下文參數(worknode1)
  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:workernode1 \
    --kubeconfig=workernode1.kubeconfig

# 設置上下文參數(worknode2)
  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:workernode2 \
    --kubeconfig=workernode2.kubeconfig

# 設置默認的上下文
kubectl config use-context default --kubeconfig=workernode1.kubeconfig
kubectl config use-context default --kubeconfig=workernode2.kubeconfig
```

- 將 workernode1.kubeconfig 複製到 D 的 `/etc/kubernetes`, workernode2.kubeconfig 複製到 E 的 `/etc/kubernetes`

## 建立 kube-proxy kubeconfig 文件
> 以下動作先在 A 進行，之後再複製到 D, E

```sh
$ cd /etc/kubernetes/ssl

# 設置 cluster 的參數
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBE_APISERVER}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

# 設定 client 端的認證參數 
kubectl config set-credentials kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

# 設置上下文參數
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

# 設置默認的上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

- 將 kube-proxy.kubeconfig 複製到 D, E 的 `/etc/kubernetes`
