# Kubernetes Node 授權

## 前言
因採 TLS Bootstrapping 都要用 TLS 驗證

## 建立 ClusterRoleBinding
> 在 master1

```
$ kubectl create clusterrolebinding kubelet-bootstrap \
    --clusterrole=system:node-bootstrapper \
    --user=kubelet-bootstrap
```

## 透過 kubectl 來允許節點加入叢集
```sh
$ kubectl get csr | awk '/Pending/ {print $1}' | xargs kubectl certificate approve
certificatesigningrequest "node-csr-S1vS01swW-Zw5QMU4UhaF7HcB_N9HD5nhE51wdY3NYo" approved
certificatesigningrequest "node-csr-lUHzLvJtQ461Vw6Af6kp3cgXWL5ME_t3q7qmVBuF9Fw" approved
```

## 驗證
```
$ kubectl get csr
NAME                                                   AGE       REQUESTOR           CONDITION
node-csr-S1vS01swW-Zw5QMU4UhaF7HcB_N9HD5nhE51wdY3NYo   31s       kubelet-bootstrap   Approved,Issued
node-csr-lUHzLvJtQ461Vw6Af6kp3cgXWL5ME_t3q7qmVBuF9Fw   23s       kubelet-bootstrap   Approved,Issued
$ kubectl get no
NAME      STATUS     ROLES     AGE       VERSION
master1   NotReady   master    1h        v1.8.8
node1     NotReady   node      31s       v1.8.8
node2     NotReady   node      30s       v1.8.8
```
