# Kubernetes Master 安裝

## Table of Contents

- [前言]()
- [安裝 kubelet & kubectl元件]()
- [下載CNI]()
- [建立 CA 與 Certificates]()
  - [建立 CA 與 CA key]()
  - [建立 API server certificate]()
  - [建立 Front proxy certificate]()
- [建立 kubelets 客戶端的 TLS Bootstrap]()
- [建立 Admin certificate & kubeconfig]()
- [建立 Controller manager certificate & kubeconfig]()
- [建立 Scheduler certificate & kubeconfig]()
- [建立 Kubelet master certificate & kubeconfig]()
- [Service account key]()
- [安裝 Kubernetes 核心元件]()

## 前言
安裝以下元件
- kube-apiserver
- kube-scheduler
- kube-controller-manager
都在 A node 進行

## 安裝 kubelet & kubectl 元件
- kubelet: 管 pod 用
- kubectl: 

- 下載與安裝 kubelet & kubectl
```sh
$ wget -q --show-progress --https-only --timestamping "https://storage.googleapis.com/kubernetes-release/release/v1.8.8/bin/linux/amd64/kubelet" -O /usr/local/bin/kubelet
$ wget -q --show-progress --https-only --timestamping "https://storage.googleapis.com/kubernetes-release/release/v1.8.8/bin/linux/amd64/kubectl" -O /usr/local/bin/kubectl
$ chmod +x /usr/local/bin/kubelet /usr/local/bin/kubectl
```

## 下載 CNI
```sh
$ mkdir -p /opt/cni/bin && cd /opt/cni/bin
$ wget -qO- --show-progress "https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz" | tar -zx
```

## 建立 CA 與 Certificates

### 建立 CA 與 CA key
1. Create folder
```sh
$ mkdir -p /etc/kubernetes/ssl && cd /etc/kubernetes/ssl
$ export KUBE_APISERVER="https://10.140.0.2:6443"
```
2. Create the CA configuration file
```sh
$ cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ], 
        "expiry": "8760h"
      }
    }
  }
}
EOF
```
3. 建立 Kubernetes 的 CA 憑證簽名請求
```sh
$ cat > ca-csr.json <<EOF
{
  "CN": "etcd",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "OU": "Kubernetes-manual",
      "O": "Kubernetes",
      "L": "Hsinchu"
    }
  ]
}
EOF
```
4. 生成 kubernetes 的 CA 憑證私鑰
```
$ cfssl gencert -initca ca-csr.json | cfssljson -bare ca
$ ls ca*.pem
ca-key.pem  ca.pem
```

### 建立 API server certificate
1. 建立 API server 的 CA 憑證簽名請求
```sh
$ cd /etc/kubernetes/ssl
$ cat > apiserver-csr.json <<EOF
{
  "CN": "kube-apiserver",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "OU": "Kubernetes-manual",
      "O": "Kubernetes",
      "L": "Hsinchu"
    }
  ]
}
EOF
```

2. 生成 API servier 的 CA 憑證私鑰
```
$ cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.96.0.1,10.140.0.2,127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  apiserver-csr.json | cfssljson -bare apiserver


$ ls apiserver*.pem
apiserver-key.pem  apiserver.pem
```

### 建立 Front proxy certificate
1. 產生 Front proxy CA 金鑰
(Front proxy 用在 API aggregator 上)  

```sh
$ cd /etc/kubernetes/ssl
$ cat > front-proxy-ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  }
}
EOF

$ cfssl gencert \
  -initca front-proxy-ca-csr.json | cfssljson -bare front-proxy-ca

$ ls front-proxy-ca*.pem
front-proxy-ca-key.pem  front-proxy-ca.pem
```
2. 產生 front-proxy-client 證書
```sh
$ cd /etc/kubernetes/ssl
$ cat > front-proxy-client-csr.json <<EOF
{
  "CN": "front-proxy-client",
  "key": {
    "algo": "rsa",
    "size": 2048
  }
}
EOF

$ cfssl gencert \
  -ca=front-proxy-ca.pem \
  -ca-key=front-proxy-ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  front-proxy-client-csr.json | cfssljson -bare front-proxy-client

$ ls front-proxy-client*.pem
front-proxy-client-key.pem  front-proxy-client.pem
```

## 建立 kubelets 客戶端的 TLS Bootstrap
```sh
$ cd /etc/kubernetes/ssl

# generate tokens
$ export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

$ cat <<EOF > /etc/kubernetes/token.csv
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

# bootstrap set-cluster
$ kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=${KUBE_APISERVER} \
    --kubeconfig=../bootstrap.conf

# bootstrap set-credentials
$ kubectl config set-credentials kubelet-bootstrap \
    --token=${BOOTSTRAP_TOKEN} \
    --kubeconfig=../bootstrap.conf

# bootstrap set-context
$ kubectl config set-context default \
    --cluster=kubernetes \
    --user=kubelet-bootstrap \
   --kubeconfig=../bootstrap.conf

# bootstrap set default context
$ kubectl config use-context default --kubeconfig=../bootstrap.conf
```

## 建立 Admin certificate & kubeconfig
1. 建立 Admin 的 CA 憑證簽名請求
```sh
$ cd /etc/kubernetes/ssl
$ cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  }, 
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "OU": "Kubernetes-manual",
      "O": "system:masters",
      "L": "Hsinchu"
    }
  ]
}
EOF
```
2. 生成 CA 憑證私鑰
```sh
$ cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

$ ls admin*.pem
admin-key.pem  admin.pem
```
3. 產生 kubeconfig
```sh
# admin set-cluster
$ kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=${KUBE_APISERVER} \
    --kubeconfig=../admin.conf

# admin set-credentials
$ kubectl config set-credentials kubernetes-admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=../admin.conf

# admin set-context
$ kubectl config set-context kubernetes-admin@kubernetes \
    --cluster=kubernetes \
    --user=kubernetes-admin \
    --kubeconfig=../admin.conf

# admin set default context
$ kubectl config use-context kubernetes-admin@kubernetes \
    --kubeconfig=../admin.conf
```

## 建立 Controller manager certificate & kubeconfig
1. 建立 Controller manager 的 CA 憑證簽名請求
```sh
$ cd /etc/kubernetes/ssl
$ cat > manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  }, 
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "OU": "Kubernetes-manual",
      "O": "system:kube-controller-manager",
      "L": "Hsinchu"
    }
  ]
}
EOF
```
2. 生成 CA 憑證私鑰
```sh
$ cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  manager-csr.json | cfssljson -bare controller-manager

$ ls controller-manager*.pem
controller-manager-key.pem  controller-manager.pem
```
3. 產生 kubeconfig
```sh
# controller-manager set-cluster
$ kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=${KUBE_APISERVER} \
    --kubeconfig=../controller-manager.conf

# controller-manager set-credentials
$ kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=controller-manager.pem \
    --client-key=controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=../controller-manager.conf

# controller-manager set-context
$ kubectl config set-context system:kube-controller-manager@kubernetes \
    --cluster=kubernetes \
    --user=system:kube-controller-manager \
    --kubeconfig=../controller-manager.conf

# controller-manager set default context
$ kubectl config use-context system:kube-controller-manager@kubernetes \
    --kubeconfig=../controller-manager.conf
```

## 建立 Scheduler certificate & kubeconfig
1. 建立 Scheduler 的 CA 憑證簽名請求
```sh
$ cd /etc/kubernetes/ssl
$ cat > scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  }, 
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "OU": "Kubernetes-manual",
      "O": "system:kube-scheduler",
      "L": "Hsinchu"
    }
  ]
}
EOF
```
2. 生成 CA 憑證私鑰
```sh
$ cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  scheduler-csr.json | cfssljson -bare scheduler

$ ls scheduler*.pem
scheduler-key.pem  scheduler.pem
```
3. 產生 kubeconfig
```sh
# scheduler set-cluster
$ kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=${KUBE_APISERVER} \
    --kubeconfig=../scheduler.conf

# scheduler set-credentials
$ kubectl config set-credentials system:kube-scheduler \
    --client-certificate=scheduler.pem \
    --client-key=scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=../scheduler.conf

# scheduler set-context
$ kubectl config set-context system:kube-scheduler@kubernetes \
    --cluster=kubernetes \
    --user=system:kube-scheduler \
    --kubeconfig=../scheduler.conf

# scheduler set default context
$ kubectl config use-context system:kube-scheduler@kubernetes \
    --kubeconfig=../scheduler.conf
```

## 建立 Kubelet master certificate & kubeconfig
1. 建立 Kubelet master 的 CA 憑證簽名請求
```sh
$ cd /etc/kubernetes/ssl
$ cat > kubelet-csr.json <<EOF
{
  "CN": "system:node:master1",
  "key": {
    "algo": "rsa",
    "size": 2048
  }, 
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "OU": "Kubernetes-manual",
      "O": "system:nodes",
      "L": "Hsinchu"
    }
  ]
}
EOF
```
2. 生成 CA 憑證私鑰
```sh
$ cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=master1,10.140.0.2 \
  -profile=kubernetes \
  kubelet-csr.json | cfssljson -bare kubelet

$ ls kubelet*.pem
kubelet-key.pem  kubelet.pem
```
3. 產生 kubeconfig
```sh
# kubelet set-cluster
$ kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=${KUBE_APISERVER} \
    --kubeconfig=../kubelet.conf

# kubelet set-credentials
$ kubectl config set-credentials system:node:master1 \
    --client-certificate=kubelet.pem \
    --client-key=kubelet-key.pem \
    --embed-certs=true \
    --kubeconfig=../kubelet.conf

# kubelet set-context
$ kubectl config set-context system:node:master1@kubernetes \
    --cluster=kubernetes \
    --user=system:node:master1 \
    --kubeconfig=../kubelet.conf

# kubelet set default context
$ kubectl config use-context system:node:master1@kubernetes \
    --kubeconfig=../kubelet.conf
```

## Service account key
```sh
$ openssl genrsa -out sa.key 2048
$ openssl rsa -in sa.key -pubout -out sa.pub
$ ls sa.*
sa.key  sa.pub
```

## 安裝 Kubernetes 核心元件

