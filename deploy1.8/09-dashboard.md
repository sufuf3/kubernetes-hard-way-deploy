# Dashboard

## 前言

## 安裝
```sh
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
$ kubectl -n kube-system get po,svc -l k8s-app=kubernetes-dashboard
```
