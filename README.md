# 手把手安裝 v1.9.x Kubernetes cluster 練習筆記

本篇是純手工安裝 Kubernetes 的練習筆記，並沒有使用自動安裝的工具來進行。  
目標是能了解 Kubernetes 的元件是怎麼組成並搭建起來。

# 練習環境(目前版本，可能會調整)
- OS: Ubuntu 16.04
- kubernetes: v1.9.3
- etcd: v2.2.5
- Go: v1.6.2

# 架構簡介
三台 Master Node，兩台 Worker Node

# 主要參考來源
- https://kubernetes.io/
- https://github.com/kelseyhightower/kubernetes-the-hard-way
- https://www.gitbook.com/book/feisky/kubernetes/details
- https://jimmysong.io/kubernetes-handbook/

