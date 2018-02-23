# Dashboard

## 前言
Ref: https://github.com/kubernetes/dashboard
https://github.com/kubernetes/dashboard/wiki/Access-control  
https://my.oschina.net/ytqvip/blog/1603951

## Generate private key and certificate signing request && Generate SSL certificate
> On master1

Ref: https://github.com/kubernetes/dashboard/wiki/Certificate-management#generate-private-key-and-certificate-signing-request
```sh
$ mkdir -p $HOME/certs && cd $HOME/certs
$ pwd
/root/certs
$ openssl genrsa -des3 -passout pass:x -out dashboard.pass.key 2048
$ openssl rsa -passin pass:x -in dashboard.pass.key -out dashboard.key
$ openssl req -new -key dashboard.key -out dashboard.csr
...
Country Name (2 letter code) [AU]: TW
...
A challenge password []:
...
$ openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt
$ rm dashboard.pass.key
```

## create secret
> on master1
```sh
$ kubectl create secret generic kubernetes-dashboard-certs --from-file=$HOME/certs -n kube-system
```


## 用 kubectl 建立 kubernetes dashboard
```sh
$ cd /etc/kubernetes/addons
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

## NodePort
https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above#nodeport
```sh
kubectl -n kube-system edit service kubernetes-dashboard
```
Change `type: ClusterIP` to `type: NodePort` and save file
