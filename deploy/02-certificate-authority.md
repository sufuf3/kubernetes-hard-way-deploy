# 02. 建立 CA 與 Certificates

## Table of Contents

## 0. 簡略概述
> 以下 1~6 步只要在 A node 進行即可，把 key 完全生成後再複製到 B~E node 。  

- 生成的 CA 證書和私鑰文件如下   
ca-key.pem  
ca.pem  
kubernetes-key.pem  
kubernetes.pem  
kube-proxy.pem  
kube-proxy-key.pem  
admin.pem  
admin-key.pem  
- 使用證書的元件如下:  
etcd: ca.pem, kubernetes-key.pem, kubernetes.pem  
kube-apiserver: ca.pem, kubernetes-key.pem, kubernetes.pem  
kubelet: ca.pem  
kube-proxy: ca.pem, kube-proxy-key.pem, kube-proxy.pem  
kubectl: ca.pem, admin-key.pem, admin.pem  
kube-controller-manager: ca-key.pem, ca.pem  
- Node 要儲存的證書:  
Master node: ca.pem, ca-key.pem, kubernetes-key.pem, kubernetes.pem  
Worker node: ca.pem worker-key.pem worker.pem  

## 1. 安裝 CFSSL 工具
> 在 A node 生成 key 就好，所以工具裝在 A 即可

CFSSL 是一個使用 go 語言的 CloudFlare 的 PKI 工具集，主要功能為 Certificate Authority (CA) 證書和私鑰文件。  
CA 是自簽名的證書，用來簽名後續建立的其它 TLS(Transport Layer Security) 證書。  

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
- ca-config.json：可以定義多個 profiles，分別指定不同的過期時間、使用場景等；後續在簽名證書時使用某個 profile
- signing：表示該證書可用於簽名其它證書；生成的 ca.pem 證書中 CA=TRUE
- server auth：表示 client 可以用該 CA 對 server 提供的證書進行驗證
- client auth：表示 server 可以用該 CA 對 client 提供的證書進行驗證

## 3. 建立 CA 證書簽名請求
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

## 4. 生成 CA 證書私鑰
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

- 生成 kubernetes證書和私鑰

```sh
$ /root/ssl
$ cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
```

產生 `kubernetes.csr, kubernetes-key.pem,  kubernetes.pem`
> **複製 `kubernetes.pem, kubernetes-key.pem` 到 A~C

## 6. 建立 admin certificate

## 7. 建立 kube-proxy certificate

## 8. 建立 Kubelet client 憑證

## 
