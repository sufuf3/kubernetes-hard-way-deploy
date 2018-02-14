# 03. 建立 kubeconfig 文件

## Table of Contents

## 前言
在上一步已經建立好 kubelet 和 kube-proxy 的憑證和私鑰。  
而 kubeconfig 是 Kubernetes client 端和 API Server 認證的保證。  

## 建立 kubectl kubeconfig 文件
> 以下動作先在 A 進行，之後再複製到 D, E (因為 A 才有 admin 的 key)

```sh
$ export KUBE_APISERVER="https://10.142.0.2:6443"
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
