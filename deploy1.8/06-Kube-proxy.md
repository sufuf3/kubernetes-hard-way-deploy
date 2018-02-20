# Kube-proxy 部署

## Table of Contents
- [前言]()
- [建立 kube-proxy certificate & kubeconfig]()
- [複製檔案到 node]()
- [建立 kube-proxy daemon]()

## 前言

## 建立 kube-proxy certificate & kubeconfig
> 在 master1 進行
1. 建立 kube-proxy 的 CA 憑證簽名請求

```sh
$ cd /etc/kubernetes/ssl

$ cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  }, 
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "OU": "Kubernetes-manual",
      "O": "system:kube-proxy",
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
  kube-proxy-csr.json | cfssljson -bare kube-proxy

$ ls kube-proxy*.pem
kube-proxy-key.pem  kube-proxy.pem
```
3. 產生 kubeconfig
```sh
# kube-proxy set-cluster
$ kubectl config set-cluster kubernetes \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server="https://10.140.0.2:6443" \
    --kubeconfig=../kube-proxy.conf

# kube-proxy set-credentials
$ kubectl config set-credentials system:kube-proxy \
    --client-key=kube-proxy-key.pem \
    --client-certificate=kube-proxy.pem \
    --embed-certs=true \
    --kubeconfig=../kube-proxy.conf

# kube-proxy set-context
$ kubectl config set-context system:kube-proxy@kubernetes \
    --cluster=kubernetes \
    --user=system:kube-proxy \
    --kubeconfig=../kube-proxy.conf

# kube-proxy set default context
$ kubectl config use-context system:kube-proxy@kubernetes \
    --kubeconfig=../kube-proxy.conf
```

## 複製檔案到 node
複製 `ssl/kube-proxy.pem ssl/kube-proxy-key.pem kube-proxy.conf` 到 B & C 的 `/etc/kubernetes/`

## 建立 kube-proxy daemon
> Master1
- 編輯 kube-proxy.yml
```sh
$ mkdir -p /etc/kubernetes/addons && cd /etc/kubernetes/addons
$ vim kube-proxy.yml
```
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-proxy
  labels:
    k8s-app: kube-proxy
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
  namespace: kube-system
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: kube-proxy
  labels:
    k8s-app: kube-proxy
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: kube-proxy
  templateGeneration: 1
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        k8s-app: kube-proxy
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      serviceAccountName: kube-proxy
      hostNetwork: true
      containers:
      - name: kube-proxy
        image: gcr.io/google_containers/kube-proxy-amd64:v1.8.8
        command:
        - kube-proxy
        - --v=0
        - --logtostderr=true
        - --kubeconfig=/run/kube-proxy.conf
        - --cluster-cidr=10.244.0.0/16
        - --proxy-mode=iptables
        imagePullPolicy: IfNotPresent
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /run/kube-proxy.conf
          name: kubeconfig
          readOnly: true
        - mountPath: /etc/kubernetes/ssl
          name: k8s-certs
          readOnly: true
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      volumes:
      - hostPath:
          path: /etc/kubernetes/kube-proxy.conf
          type: FileOrCreate
        name: kubeconfig
      - hostPath:
          path: /etc/kubernetes/ssl
          type: DirectoryOrCreate
        name: k8s-certs
```

```sh
$ kubectl apply -f kube-proxy.yml
```
- 驗證
```sh
$ kubectl -n kube-system get po -l k8s-app=kube-proxy
NAME               READY     STATUS              RESTARTS   AGE
kube-proxy-fngcn   0/1       ContainerCreating   0          6s
kube-proxy-k55v8   0/1       ContainerCreating   0          6s
kube-proxy-snj25   0/1       ContainerCreating   0          6s

$ kubectl -n kube-system get po -l k8s-app=kube-proxy
NAME               READY     STATUS    RESTARTS   AGE
kube-proxy-fngcn   1/1       Running   0          24s
kube-proxy-k55v8   1/1       Running   0          24s
kube-proxy-snj25   1/1       Running   0          24s
```
