# 02. 建立 CA 與 Certificates

## Table of Contents

## 0. 簡略概述
> 以下 1~6 步只要在 A node 進行即可，把 key 完全生成後再複製到 B~E node 。  

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

```shell=
$ sudo su -
$ mkdir /root/ssl
$ cd /root/ssl
$ cfssl print-defaults config > config.json
$ cfssl print-defaults csr > csr.json
$ cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
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
- 編輯 ca-csr.json 文件
```
$ vim /root/ssl/ca-csr.json
```
- 編輯內容
```javascript
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "L": "Hsinchu",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
```

## 4. 生成 CA 憑證私鑰
> 在 A 建立

```sh
$ cd /root/ssl
$ cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

生成 ca.pem, ca.csr, ca-key.pem(CA 私鑰,要保管好)  

> **複製 `ca.pem, ca-key.pem` 到 A~C, 複製 `ca.pem` 到 D~E，都在 /etc/kubernetes/ssl/ 底下**

## 5. 建立 kubernetes API certificate
> 在 A 建立

保證 client 端和 Kubernetes API 的驗證  

- 編輯 kubernetes-csr.json  
```sh
$ vim /root/ssl/kubernetes-csr.json
```

- 編輯內容  
```javascript
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "10.142.0.2",
      "10.142.0.3",
      "10.142.0.4",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "TW",
            "ST": "Hsinchu",
            "L": "Hsinchu",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
```

- 生成 kubernetes憑證和私鑰

```sh
$ /root/ssl
$ cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
```

產生 `kubernetes.csr, kubernetes-key.pem,  kubernetes.pem`
> **複製 `kubernetes.pem, kubernetes-key.pem` 到 A~C

## 6. 建立 admin certificate
> 在 A 建立

用於 Kubernetes admin 使用者的 client 憑證。

- 建立 admin-csr.json 檔案
```sh
vim /root/ssl/admin-csr.json
```

- 編輯內容
```javascript
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "L": "Hsinchu",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
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
vim /root/ssl/kube-proxy-csr.json
```
- 編輯內容
```javascript=
{
"CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "L": "Hsinchu",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
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

### 給 Worknode 1
- 建立 worknode1-csr.json 文件
```
vim /root/ssl/worknode1-csr.json
```
- 編輯內容
```sh
{
"CN": "system:node:worknode1",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "L": "Hsinchu",
      "O": "system:nodes",
      "OU": "System"
    }
  ]
}
```
- 生成憑證和私鑰
```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=worknode1,10.142.0.5 -profile=kubernetes worknode1-csr.json | cfssljson -bare worknode1
```
> **Copy `worknode1.pem worknode1-key.pem` in D**

### 給 Worknode 2
- 建立 worknode2-csr.json 文件
```
vim /root/ssl/worknode2-csr.json
```
- 編輯內容
```sh
{
"CN": "system:node:worknode1",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "L": "Hsinchu",
      "O": "system:nodes",
      "OU": "System"
    }
  ]
}
```
- 生成憑證和私鑰
```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=worknode1,10.142.0.6 -profile=kubernetes worknode2-csr.json | cfssljson -bare worknode2
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
