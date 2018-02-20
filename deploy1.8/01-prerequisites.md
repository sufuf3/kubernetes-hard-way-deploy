# 01. Node 架構與準備

## Table of Contents
- [Node 的相關資訊](#node-%E7%9A%84%E7%9B%B8%E9%97%9C%E8%B3%87%E8%A8%8A)
- [更新]()
- [編輯`/etc/hosts`]()
- [安裝 Docker](#%E5%AE%89%E8%A3%9D-docker)
- [設定 routing]()
- [安裝 Go](#%E5%AE%89%E8%A3%9D-go)
- [安裝 CFSSL 工具]()

## Node 的相關資訊
本份文件皆使用這份清單來進行

| ID | role | hostname | private IP | public IP |
| --- | --- | --- | --- | --- |
| A | master,etcd | master1 | 10.140.0.2 | XX.XXX.XX.XX |
| B | worker | node1 | 10.140.0.3 | XX.XXX.XX.XXX |
| C | worker | node2 | 10.140.0.4 | XX.XXX.XX.XX |

## 更新
> All nodes (A~C)
```
sudo apt update && sudo apt upgrade -y
```

## 編輯 `/etc/hosts`
> All nodes (A~C)

解析用。方便之後的設定檔編輯。
```
sudo vim /etc/hosts
```
```
10.140.0.2 master1
10.140.0.3 node1
10.140.0.4 node2
```

## 安裝 Docker

> 安裝到 A~C node

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

3. 編輯 `/lib/systemd/system/docker.service`
> All nodes (A~c)

在ExecStart=..上方加入
```sh
ExecStartPost=/sbin/iptables -A FORWARD -s 0.0.0.0/0 -j ACCEPT
```

4. 重啟 docker service
```
systemctl daemon-reload && systemctl restart docker
```

## 設定 routing

> A~C node

```sh
$ cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

$ sysctl -p /etc/sysctl.d/k8s.conf
```

## 安裝 Go

> 安裝到 A node

```sh
$ sudo add-apt-repository ppa:longsleep/golang-backports
$ sudo apt-get update
$ sudo apt-get install golang-go -y
```
Ref: https://github.com/golang/go/wiki/Ubuntu

## 安裝 CFSSL 工具

> 安裝到 A node

CFSSL 是一個使用 go 語言的 CloudFlare 的 PKI 工具集，主要功能為 Certificate Authority (CA) 憑證和私鑰文件。  
CA 是自簽名的憑證，用來簽名後續建立的其它 TLS(Transport Layer Security) 憑證。  

```sh
$ go get -u github.com/cloudflare/cfssl/cmd/...

$ sudo cp go/bin/cfssl* /usr/local/bin/
```

This will download, build, and install all of the utility programs (including `cfssl`, `cfssljson`, and `mkbundle` among others) into the `$GOPATH/bin/` directory.  
Ref: https://github.com/cloudflare/cfssl#installation  
