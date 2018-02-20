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
- [設定與啟用 Secret data]()
- [建立 Audit Policy]()
- [設定與重新啟動 kubelet]()
- [編輯 ~/.kube/config]()
- [RBAC 設定]()
- [驗證]()

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
使用 Kubernetes Static Pod 安裝元件  
```sh
$ mkdir -p /etc/kubernetes/manifests && cd /etc/kubernetes/manifests
```

- kube-apiserver
```sh
$ vim apiserver.yml
```
```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  hostNetwork: true
  containers :
  - name: kube-apiserver
    image: gcr.io/google_containers/kube-apiserver-amd64:v1.8.8
    command:
      - kube-apiserver
      - --v=0
      - --logtostderr=true
      - --allow-privileged=true
      - --bind-address=0.0.0.0
      - --secure-port=6443
      - --insecure-port=0
      - --advertise-address=10.140.0.2
      - --service-cluster-ip-range=10.96.0.0/12
      - --service-node-port-range=30000-32767
      - --etcd-servers=https://10.140.0.2:2379
      - --etcd-cafile=/etc/etcd/ssl/etcd-ca.pem
      - --etcd-certfile=/etc/etcd/ssl/etcd.pem
      - --etcd-keyfile=/etc/etcd/ssl/etcd-key.pem
      - --client-ca-file=/etc/kubernetes/ssl/ca.pem
      - --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem
      - --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
      - --kubelet-client-certificate=/etc/kubernetes/ssl/apiserver.pem
      - --kubelet-client-key=/etc/kubernetes/ssl/apiserver-key.pem
      - --service-account-key-file=/etc/kubernetes/ssl/sa.pub
      - --token-auth-file=/etc/kubernetes/token.csv
      - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
      - --admission-control=Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,ResourceQuota
      - --authorization-mode=Node,RBAC
      - --enable-bootstrap-token-auth=true
      - --requestheader-client-ca-file=/etc/kubernetes/ssl/front-proxy-ca.pem
      - --proxy-client-cert-file=/etc/kubernetes/ssl/front-proxy-client.pem
      - --proxy-client-key-file=/etc/kubernetes/ssl/front-proxy-client-key.pem
      - --requestheader-allowed-names=aggregator
      - --requestheader-group-headers=X-Remote-Group
      - --requestheader-extra-headers-prefix=X-Remote-Extra-
      - --requestheader-username-headers=X-Remote-User
      - --audit-log-maxage=30
      - --audit-log-maxbackup=3
      - --audit-log-maxsize=100
      - --audit-log-path=/var/log/kubernetes/audit.log
      - --audit-policy-file=/etc/kubernetes/audit-policy.yml
      - --experimental-encryption-provider-config=/etc/kubernetes/encryption.yml
      - --event-ttl=1h
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 6443
        scheme: HTTPS
      initialDelaySeconds: 15
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 250m
    volumeMounts:
    - mountPath: /var/log/kubernetes
      name: k8s-audit-log
    - mountPath: /etc/kubernetes/ssl
      name: k8s-certs
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
    - mountPath: /etc/kubernetes/encryption.yml
      name: encryption-config
      readOnly: true
    - mountPath: /etc/kubernetes/audit-policy.yml
      name: audit-config
      readOnly: true
    - mountPath: /etc/kubernetes/token.csv
      name: token-csv
      readOnly: true
    - mountPath: /etc/etcd/ssl
      name: etcd-ca-certs
      readOnly: true
  volumes:
  - hostPath:
      path: /var/log/kubernetes
      type: DirectoryOrCreate
    name: k8s-audit-log
  - hostPath:
      path: /etc/kubernetes/ssl
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /etc/kubernetes/encryption.yml
      type: FileOrCreate
    name: encryption-config
  - hostPath:
      path: /etc/kubernetes/audit-policy.yml
      type: FileOrCreate
    name: audit-config
  - hostPath:
      path: /etc/kubernetes/token.csv
      type: FileOrCreate
    name: token-csv
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /etc/etcd/ssl
      type: DirectoryOrCreate
    name: etcd-ca-certs
```

- kube-controller-manager

```sh
$ vim manager.yml
```
```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: kube-controller-manager
    tier: control-plane
  name: kube-controller-manager
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-controller-manager
    image: gcr.io/google_containers/kube-controller-manager-amd64:v1.8.8
    command:
      - kube-controller-manager
      - --v=0
      - --logtostderr=true
      - --address=127.0.0.1
      - --root-ca-file=/etc/kubernetes/ssl/ca.pem
      - --cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem
      - --cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem
      - --service-account-private-key-file=/etc/kubernetes/ssl/sa.key
      - --kubeconfig=/etc/kubernetes/controller-manager.conf
      - --leader-elect=true
      - --use-service-account-credentials=true
      - --node-monitor-grace-period=40s
      - --node-monitor-period=5s
      - --pod-eviction-timeout=2m0s
      - --controllers=*,bootstrapsigner,tokencleaner
      - --allocate-node-cidrs=true
      - --cluster-cidr=10.244.0.0/16
      - --node-cidr-mask-size=24
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10252
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 200m
    volumeMounts:
    - mountPath: /etc/kubernetes/ssl
      name: k8s-certs
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
    - mountPath: /etc/kubernetes/controller-manager.conf
      name: kubeconfig
      readOnly: true
    - mountPath: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
      name: flexvolume-dir
  volumes:
  - hostPath:
      path: /etc/kubernetes/ssl
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /etc/kubernetes/controller-manager.conf
      type: FileOrCreate
    name: kubeconfig
  - hostPath:
      path: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
      type: DirectoryOrCreate
    name: flexvolume-dir
```

- kube-scheduler

```sh
$ vim scheduler.yml
```
```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-scheduler
    image: gcr.io/google_containers/kube-scheduler-amd64:v1.8.8
    command:
      - kube-scheduler
      - --v=0
      - --logtostderr=true
      - --address=127.0.0.1
      - --leader-elect=true
      - --kubeconfig=/etc/kubernetes/scheduler.conf
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10251
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 100m
    volumeMounts:
    - mountPath: /etc/kubernetes/ssl
      name: k8s-certs
      readOnly: true
    - mountPath: /etc/kubernetes/scheduler.conf
      name: kubeconfig
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/ssl
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /etc/kubernetes/scheduler.conf
      type: FileOrCreate
    name: kubeconfig
```

## 設定與啟用 Secret data

一般情况下，etcd 包含了通過 Kubernetes API 可以拿到所有資料，可以讓授予 etcd 的使用者對 cluster 進行攻擊。  
因此需要來對這些資料進行加密。  
k8s 使用 rest 加密機制，它是 α 特性，会加密 etcd 裡面的 Secret 資源，以防止某一方通過查看这些 secret 的内容獲得 etcd 的備份。  
所以這邊要來設定與啟用 rest 加密 etcd 中的 secret data 的機制。  
  
Ref:  
https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/  
https://k8smeetup.github.io/docs/tasks/administer-cluster/securing-a-cluster/  

1. 建立加密密鑰
```sh
$ head -c 32 /dev/urandom | base64
Nekla5byJTwg8Bz4eHnQ7DQpSBvD+YE6AU6ofPUNpYk=
```
2. 加密配置設定
```sh
$ cat <<EOF > /etc/kubernetes/encryption.yml
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: Nekla5byJTwg8Bz4eHnQ7DQpSBvD+YE6AU6ofPUNpYk=
      - identity: {}
EOF
```

## 建立 Audit Policy

```sh
$ cat <<EOF > /etc/kubernetes/audit-policy.yml
apiVersion: audit.k8s.io/v1beta1
kind: Policy
rules:
- level: Metadata
EOF
```
## 設定與重新啟動 kubelet
```sh
$ mkdir -p /etc/systemd/system/kubelet.service.d
```
```sh
$ vim /lib/systemd/system/kubelet.service
```
```yaml
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=http://kubernetes.io/docs/

[Service]
ExecStart=/usr/local/bin/kubelet
Restart=on-failure
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
```
```sh
vim /etc/systemd/system/kubelet.service.d/10-kubelet.conf
```
```yaml
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--address=0.0.0.0 --port=10250 --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBE_LOGTOSTDERR=--logtostderr=true --v=0"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true --anonymous-auth=false"
Environment="KUBELET_POD_CONTAINER=--pod-infra-container-image=gcr.io/google_containers/pause:3.0"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/ssl/ca.pem"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false --serialize-image-pulls=false"
Environment="KUBE_NODE_LABEL=--node-labels=node-role.kubernetes.io/master=true"
ExecStart=
ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBE_LOGTOSTDERR $KUBELET_POD_CONTAINER $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_EXTRA_ARGS $KUBE_NODE_LABEL
```
- 重新啟動
```sh
$ mkdir -p /var/lib/kubelet /var/log/kubernetes
$ systemctl enable kubelet.service && systemctl start kubelet.service
```
- Check
```sh
$ netstat -ntlp
```

## 編輯 ~/.kube/config
```sh
$ cp /etc/kubernetes/admin.conf ~/.kube/config
```

## RBAC 設定

## 驗證

