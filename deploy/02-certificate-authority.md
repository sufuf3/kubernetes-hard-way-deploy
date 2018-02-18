# 02. 建立 CA 與 Certificates

## Table of Contents
- [0. 簡略概述](#0-%E7%B0%A1%E7%95%A5%E6%A6%82%E8%BF%B0)
- [1. 安裝 CFSSL 工具](#1-%E5%AE%89%E8%A3%9D-cfssl-%E5%B7%A5%E5%85%B7)
- [2. 建立 CA (Certificate Authority)](#2-%E5%BB%BA%E7%AB%8B-ca-certificate-authority)
- [3. 建立 CA 憑證簽名請求](#3-%E5%BB%BA%E7%AB%8B-ca-%E6%86%91%E8%AD%89%E7%B0%BD%E5%90%8D%E8%AB%8B%E6%B1%82)
- [4. 生成 CA 憑證私鑰](#4-%E7%94%9F%E6%88%90-ca-%E6%86%91%E8%AD%89%E7%A7%81%E9%91%B0)
- [5. 建立 kubernetes API certificate](#5-%E5%BB%BA%E7%AB%8B-kubernetes-api-certificate)
- [6. 建立 admin certificate](#6-%E5%BB%BA%E7%AB%8B-admin-certificate)
- [7. 建立 kube-proxy certificate](#7-%E5%BB%BA%E7%AB%8B-kube-proxy-certificate)
- [8. 建立 Kubelet client 憑證](#8-%E5%BB%BA%E7%AB%8B-kubelet-client-%E6%86%91%E8%AD%89)
  * [給 Worknode 1](%E7%B5%A6-worknode-1)
  * [給 Worknode 2](#%E7%B5%A6-worknode-2)
- [複製檔案](#%E8%A4%87%E8%A3%BD%E6%AA%94%E6%A1%88)

## 0. 簡略概述
> 以下 1-8 步只要在 A node 進行即可，把 key 完全生成後再複製到 B~E node 。  

- 生成的 CA 憑證和私鑰文件如下   
ca-key.pem  
ca.pem  
kubernetes-key.pem  
kubernetes.pem  
kube-proxy.pem  
kube-proxy-key.pem  
admin.pem  
admin-key.pem  
- 使用憑證的元件如下:  
etcd: ca.pem, kubernetes-key.pem, kubernetes.pem  
kube-apiserver: ca.pem, kubernetes-key.pem, kubernetes.pem  
kubelet: ca.pem  
kube-proxy: ca.pem, kube-proxy-key.pem, kube-proxy.pem  
kubectl: ca.pem, admin-key.pem, admin.pem  
kube-controller-manager: ca-key.pem, ca.pem  
- Node 要儲存的憑證:  
Master node: ca.pem, ca-key.pem, kubernetes-key.pem, kubernetes.pem  
Worker node: ca.pem worker-key.pem worker.pem  

## 1. 安裝 CFSSL 工具
> 在 A node 生成 key 就好，所以工具裝在 A 即可

CFSSL 是一個使用 go 語言的 CloudFlare 的 PKI 工具集，主要功能為 Certificate Authority (CA) 憑證和私鑰文件。  
CA 是自簽名的憑證，用來簽名後續建立的其它 TLS(Transport Layer Security) 憑證。  

```sh
$ go get -u github.com/cloudflare/cfssl/cmd/...

$ sudo cp go/bin/cfssl* /usr/local/bin/
```

This will download, build, and install all of the utility programs (including `cfssl`, `cfssljson`, and `mkbundle` among others) into the `$GOPATH/bin/` directory.
Ref: https://github.com/cloudflare/cfssl#installation

## 2. 建立 CA (Certificate Authority)
> 在 A 建立

根據 cfssl 產生出來的 config.json template 格式來建立 ca-config.json 文件。  
- 創建路徑

```sh
$ sudo su -
$ mkdir -p /etc/kubernetes/ssl
$ cd /etc/kubernetes/ssl
```

- Create the CA configuration file  

```sh
$ cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
```

Note:
- ca-config.json：可以定義多個 profiles，分別指定不同的過期時間、使用場景等；後續在簽名憑證時使用某個 profile
- signing：表示該憑證可用於簽名其它憑證；生成的 ca.pem 證書中 CA=TRUE
- server auth：表示 client 可以用該 CA 對 server 提供的憑證進行驗證
- client auth：表示 server 可以用該 CA 對 client 提供的憑證進行驗證

## 3. 建立 CA 憑證簽名請求
> 在 A 建立

根據第二步驟的 cfssl 產生出來的 csr.json template 格式來建立 ca-csr.json 文件。  

- Create the CA certificate signing request  

```sh
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "L": "Hsinchu",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Hsinchu"
    }
  ]
}
EOF
```

## 4. 生成 CA 憑證私鑰
> 在 A 建立

```sh
$ cd /etc/kubernetes/ssl
$ cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

生成 ca.pem, ca.csr, ca-key.pem(CA 私鑰,要保管好)  

> **複製 `ca.pem, ca-key.pem` 到 A~C, 複製 `ca.pem` 到 D-E，都在 /etc/kubernetes/ssl/ 底下**

## 5. 建立 kubernetes API certificate
> 在 A 建立

保證 client 端和 Kubernetes API 的驗證  

- 編輯 kubernetes-csr.json  
```sh
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "L": "Hsinchu",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Hsinchu"
    }
  ]
}
EOF
```


- 生成 kubernetes憑證和私鑰

```sh
$ cd /etc/kubernetes/ssl
$ cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.140.0.2,10.140.0.3,10.140.0.4,10.140.0.1,35.229.192.27,127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
```

產生 `kubernetes.csr, kubernetes-key.pem,  kubernetes.pem`
> **複製 `kubernetes.pem, kubernetes-key.pem` 到 A~C

## 6. 建立 admin certificate
> 在 A 建立

用於 Kubernetes admin 使用者的 client 憑證。

- 建立 admin-csr.json 檔案
```sh
cd /etc/kubernetes/ssl

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "L": "Hsinchu",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Hsinchu"
    }
  ]
}
EOF
```
- 生成 admin 憑證與私鑰
```sh
$ cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
```

Admin 憑證，是用來生成管理員用的 kube config 配置文件用的。一般建議使用 RBAC 對 kubernetes 進行角色權限控制， kubernetes 将憑證中的 CN 欄位作為 User， O 欄位為 Group。

## 7. 建立 kube-proxy certificate
> 在 A 建立

Reflects services as defined in the Kubernetes API on each node

- 建立 kube-proxy-csr.json 檔案
```sh
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "L": "Hsinchu",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Hsinchu"
    }
  ]
}
EOF
```
Note:  
- CN 欄位指定該憑證的 User 是 system:kube-proxy
- 生成 kube-proxy client 端憑證與私鑰

```sh
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
```

生成 kube-proxy.csr, kube-proxy-key.pem, kube-proxy.pem

> **Copy `kube-proxy.pem kube-proxy-key.pem` in D~E

## 8. 建立 Kubelet client 憑證
> 在 A 建立，完成後將 key 複製到 worker node

使用 Node Authorizer 授權來自 Kubelet 的 API 請求。為了要通過 Node Authorizer 的授權, Kubelet 必須使用名稱 system:node:<nodeName> 的憑證來證明它屬於 system:nodes 用户组。  

### 給 Workernode 1
- 建立 workernode1-csr.json 文件
```
cat > workernode1-csr.json <<EOF
{
  "CN": "system:node:workernode1",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "L": "Hsinchu",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Hsinchu"
    }
  ]
}
EOF
```
- 生成憑證和私鑰
```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=workernode1,10.140.0.5 -profile=kubernetes workernode1-csr.json | cfssljson -bare workernode1
```
> **Copy `worknode1.pem worknode1-key.pem` in D**

### 給 Worknode 2
- 建立 workernode2-csr.json 文件
```
cat > workernode2-csr.json <<EOF
{
  "CN": "system:node:workernode2",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "L": "Hsinchu",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Hsinchu"
    }
  ]
}
EOF
```
- 生成憑證和私鑰
```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=workernode2,10.140.0.6 -profile=kubernetes workernode2-csr.json | cfssljson -bare workernode2
```
> **Copy `worknode2.pem worknode2-key.pem` in E**

## 複製檔案
- Master node  
ca.pem  
ca-key.pem  
kubernetes-key.pem  
kubernetes.pem  

- Worker node 1  
ca.pem  
worknode1-key.pem  
worknode1.pem  
kube-proxy.pem  
kube-proxy-key.pem  

- Worker node 2  
ca.pem  
worknode2-key.pem  
worknode2.pem  
kube-proxy.pem  
kube-proxy-key.pem  
