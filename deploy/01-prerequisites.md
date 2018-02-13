# 01. Node 架構與準備
## Node 的相關資訊
本份文件皆使用這份清單來進行

| ID | role | hostname | private IP | public IP |
| --- | --- | --- | --- | --- |
| A | master,etcd | master | 10.142.0.2 | XX.XXX.XX.XX |
| B | master,etcd | node1 | 10.142.0.3 | XX.XXX.XX.XXX |
| C | master,etcd | node2 | 10.142.0.4 | XX.XXX.XX.XXX |
| D | worker | workernode1 | 10.142.0.5 | XX.XXX.XX.XXX |
| E | worker | workernode2 | 10.142.0.6 | XX.XXX.XX.XX |

## 安裝 Docker

> 安裝到 A~E node

1. 安裝 docker ，之後將自己的 username 增加到 Docker 這次要群組的支援。在登出後登入，就可以完全使用 Docker 指令。
```sh
$ curl -sSL https://get.docker.com/ | sh
$ sudo usermod -aG docker <username>
$ logout
```

2. 再次登入檢查 Docker 版本

```sh
$ docker version
Client:
 Version:       18.02.0-ce
 API version:   1.36
 Go version:    go1.9.3
 Git commit:    fc4de44
 Built: Wed Feb  7 21:16:33 2018
 OS/Arch:       linux/amd64
 Experimental:  false
 Orchestrator:  swarm

Server:
 Engine:
  Version:      18.02.0-ce
  API version:  1.36 (minimum version 1.12)
  Go version:   go1.9.3
  Git commit:   fc4de44
  Built:        Wed Feb  7 21:15:05 2018
  OS/Arch:      linux/amd64
  Experimental: false
```

## 安裝 Go

> 安裝到 A~E node

```sh
$ sudo add-apt-repository ppa:longsleep/golang-backports
$ sudo apt-get update
$ sudo apt-get install golang-go -y
```
Ref: https://github.com/golang/go/wiki/Ubuntu

# 安裝 kubectl

> 安裝到 A~E node

kubectl 是用来和 Kubernetes API Server 溝通的 CLI 介面。
```sh
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

$ chmod +x ./kubectl
$ sudo mv ./kubectl /usr/local/bin/kubectl
```
Ref: https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-via-curl
