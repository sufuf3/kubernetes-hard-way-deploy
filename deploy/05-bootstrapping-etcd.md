# 05. 部署 etcd

## Table of Contents
- [前言](#%E5%89%8D%E8%A8%80)
- [安裝 etcd](#%E5%AE%89%E8%A3%9D-etcd)
- [設定 etcd](#%E8%A8%AD%E5%AE%9A-etcd)
- [啟動 etcd Server](#%E5%95%9F%E5%8B%95-etcd-server)
- [驗證 etcd 集群](#%E9%A9%97%E8%AD%89-etcd-%E9%9B%86%E7%BE%A4)

## 前言
etcd 是可靠的分散式 key-value 儲存，是用 go 語言寫的。有以下幾個好處:  
- Simple: well-defined, user-facing API (gRPC)  
- Secure: automatic TLS with optional client cert authentication  
- Fast: benchmarked 10,000 writes/sec  
- Reliable: properly distributed using Raft  
https://coreos.com/etcd/docs/latest/  
https://github.com/coreos/etcd  
  
會需要安裝 etcd 是因為 kubernetes 的元件們大多數是 Stateless ，所以 cluster 的狀態要儲存在 etcd 中。
而且如果其中有一台掛掉，可以透過 etcd 的投票機制讓資料復原，可以確保服務比較不會有中斷現象。
如果 master 綁在 etcd 上，那可以協助票選出主要的那一台 master 。
本次練習的架構上，是 master 和 etcd 裝在同一台 host (Node)中，但其實 etcd 是 `Distributed reliable key-value store for the most critical data of a distributed system`。

## 安裝 etcd

> 在 A~C 都安裝

```sh
$ sudo su -
$ apt install etcd
```
Node: etcd 指令在 `/usr/bin` 底下

## 設定 etcd

> 在 A~C 設定

- 把 key 放到 /etc/etcd 底下(網路教學，猜是是因為設定檔不想要和 /etc/kubernetes 底下的 key 一起設定進去)

```sh
$ mkdir -p /etc/etcd
$ cd /etc/kubernetes/ssl
$ cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```
- 新增 etcd service 設定檔
```
vim /etc/systemd/system/etcd.service
```
- 編輯 A node 的設定檔

```yaml
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd \
  --name master \
  --cert-file /etc/etcd/kubernetes.pem \
  --key-file /etc/etcd/kubernetes-key.pem \
  --peer-cert-file /etc/etcd/kubernetes.pem \
  --peer-key-file /etc/etcd/kubernetes-key.pem \
  --trusted-ca-file /etc/etcd/ca.pem \
  --peer-trusted-ca-file /etc/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://10.140.0.2:2380 \
  --listen-peer-urls https://10.140.0.2:2380 \
  --listen-client-urls https://10.140.0.2:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://10.140.0.2:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster master=https://10.140.0.2:2380,node1=https://10.140.0.3:2380,node2=https://10.140.0.4:2380 \
  --initial-cluster-state new \
  --data-dir /var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

- 編輯 B node 的設定檔

```yaml
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd \
  --name node1 \
  --cert-file /etc/etcd/kubernetes.pem \
  --key-file /etc/etcd/kubernetes-key.pem \
  --peer-cert-file /etc/etcd/kubernetes.pem \
  --peer-key-file /etc/etcd/kubernetes-key.pem \
  --trusted-ca-file /etc/etcd/ca.pem \
  --peer-trusted-ca-file /etc/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://10.140.0.3:2380 \
  --listen-peer-urls https://10.140.0.3:2380 \
  --listen-client-urls https://10.140.0.3:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://10.140.0.3:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster master=https://10.140.0.2:2380,node1=https://10.140.0.3:2380,node2=https://10.140.0.4:2380 \
  --initial-cluster-state new \
  --data-dir /var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

- 編輯 C node 的設定檔

```yaml
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd \
  --name node2 \
  --cert-file /etc/etcd/kubernetes.pem \
  --key-file /etc/etcd/kubernetes-key.pem \
  --peer-cert-file /etc/etcd/kubernetes.pem \
  --peer-key-file /etc/etcd/kubernetes-key.pem \
  --trusted-ca-file /etc/etcd/ca.pem \
  --peer-trusted-ca-file /etc/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://10.140.0.4:2380 \
  --listen-peer-urls https://10.140.0.4:2380 \
  --listen-client-urls https://10.140.0.4:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://10.140.0.4:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster master=https://10.140.0.2:2380,node1=https://10.140.0.3:2380,node2=https://10.140.0.4:2380 \
  --initial-cluster-state new \
  --data-dir /var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

- `--initial-advertise-peer-urls` 是 A, B, C 的 IP:2380
Node: 
- `--name` 後面要接的 string 是 hostname，Node A 的 hostname 是 master 所以就是填 master ， Node B 的 hostname 是 node1 所以就填 node1，Node C 的 hostname 是 node2 所以填 node2。
- `--initial-advertise-peer-urls` 是 A, B, C 的 IP:2380
Node: 
- `--name` 後面要接的 string 是 hostname，Node A 的 hostname 是 master 所以就是填 master ， Node B 的 hostname 是 node1 所以就填 node1，Node C 的 hostname 是 node2 所以填 node2。
- `--initial-advertise-peer-urls` 是 A, B, C 的 IP:2380
- `--listen-peer-urls` 是 A, B, C 的 IP:2380
- `--listen-client-urls` 是 A, B, C 的 IP:2380
Ref: https://coreos.com/etcd/docs/latest/v2/clustering.html

## 啟動 etcd Server
> 在 A~C 啟動

```sh
sudo mv etcd.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

## 驗證 etcd 集群
> 在 A~C 執行看看

```
etcdctl \
  --ca-file=/etc/etcd/ca.pem \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  cluster-health

member 818a156c77978609 is healthy: got healthy result from https://10.140.0.3:2379
member 97a1672c4a2124ea is healthy: got healthy result from https://10.140.0.4:2379
member faabc16c3c835e9b is healthy: got healthy result from https://10.140.0.2:2379
cluster is healthy
```
