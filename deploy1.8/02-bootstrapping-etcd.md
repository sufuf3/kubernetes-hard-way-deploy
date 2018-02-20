# 02. 部署 etcd

## Table of Contents
- [前言](#%E5%89%8D%E8%A8%80)
- [建立 CA 與 Certificates]()
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
**所以以下都只在 A node 進行。**

## 建立 CA 與 Certificates
1. 建立資料夾
```sh
$ sudo su -
$ mkdir -p /etc/etcd/ssl && cd /etc/etcd/ssl
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
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
```
Note:
- ca-config.json：可以定義多個 profiles，分別指定不同的過期時間、使用場景等；後續在簽名憑證時使用某個 profile
- signing：表示該憑證可用於簽名其它憑證；生成的 ca.pem 證書中 CA=TRUE
- server auth：表示 client 可以用該 CA 對 server 提供的憑證進行驗證
- client auth：表示 server 可以用該 CA 對 client 提供的憑證進行驗證

3. 建立 etcd 的 CA 憑證簽名請求
```sh
$ cat > etcd-ca-csr.json <<EOF
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
      "OU": "Etcd Security",
      "O": "etcd",
      "L": "Hsinchu"
    }
  ]
}
EOF
```
4. 生成 etcd 的 CA 憑證私鑰
```sh
$ cfssl gencert -initca etcd-ca-csr.json | cfssljson -bare etcd-ca
$ ls etcd-ca*.pem
etcd-ca-key.pem  etcd-ca.pem
```
5. 建立 etcd-csr.json 檔案並 Etcd certificate 證書
```sh
$ cat > etcd-csr.json <<EOF
{
  "hosts": [
    "127.0.0.1",
    "10.140.0.2"
  ], 
  "CN": "etcd",
  "key": {
    "algo": "rsa",
    "size": 2048
  }, 
  "names": [
    {
      "C": "TW",
      "ST": "Hsinchu",
      "OU": "Etcd Security",
      "O": "etcd",
      "L": "Hsinchu"
    }
  ]
}
EOF

$ cfssl gencert \
  -ca=etcd-ca.pem \
  -ca-key=etcd-ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  etcd-csr.json | cfssljson -bare etcd

$ ls etcd*.pem
etcd-ca-key.pem  etcd-ca.pem  etcd-key.pem  etcd.pem
```

## 安裝 etcd

> 在 A 安裝

1. 下載 Etcd
(不能用 apt 裝，因為要版本 3 以上)
```sh
$ sudo su -
$ cd && wget -qO- --show-progress "https://github.com/coreos/etcd/releases/download/v3.2.9/etcd-v3.2.9-linux-amd64.tar.gz" | tar -zx
$ mv etcd-v3.2.9-linux-amd64/etcd* /usr/local/bin/ && rm -rf etcd-v3.2.9-linux-amd64
```
2. 新建 Etcd Group 與 User
```
$ groupadd etcd && useradd -c "Etcd user" -g etcd -s /sbin/nologin -r etcd
```

## 設定 etcd

> 在 A 設定

- 新增 `/etc/etcd/etcd.conf`
```
vim /etc/etcd/etcd.conf
```
- 編輯
```yaml
# [member]
ETCD_NAME=master1
ETCD_DATA_DIR=/var/lib/etcd
ETCD_LISTEN_PEER_URLS=https://0.0.0.0:2380
ETCD_LISTEN_CLIENT_URLS=https://0.0.0.0:2379
ETCD_PROXY=off

# [cluster]
ETCD_ADVERTISE_CLIENT_URLS=https://10.140.0.2:2379
ETCD_INITIAL_ADVERTISE_PEER_URLS=https://10.140.0.2:2380
ETCD_INITIAL_CLUSTER=master1=https://10.140.0.2:2380
ETCD_INITIAL_CLUSTER_STATE=new
ETCD_INITIAL_CLUSTER_TOKEN=etcd-k8s-cluster

# [security]
ETCD_CERT_FILE="/etc/etcd/ssl/etcd.pem"
ETCD_KEY_FILE="/etc/etcd/ssl/etcd-key.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-ca.pem"
ETCD_AUTO_TLS="true"
ETCD_PEER_CERT_FILE="/etc/etcd/ssl/etcd.pem"
ETCD_PEER_KEY_FILE="/etc/etcd/ssl/etcd-key.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/ssl/etcd-ca.pem"
ETCD_PEER_AUTO_TLS="true"
```

- 新增 etcd service 設定檔
```
vim /lib/systemd/system/etcd.service
```
- 編輯設定檔

```yaml
[Unit]
Description=Etcd Service
After=network.target

[Service]
Environment=ETCD_DATA_DIR=/var/lib/etcd/default
EnvironmentFile=-/etc/etcd/etcd.conf
Type=notify
User=etcd
PermissionsStartOnly=true
ExecStart=/usr/local/bin/etcd
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```
- 建立 var 存放資訊
```
$ mkdir -p /var/lib/etcd && chown etcd:etcd -R /var/lib/etcd /etc/etcd
```

Ref: https://coreos.com/etcd/docs/latest/v2/clustering.html

## 啟動 etcd Server
> 在 A 啟動

```sh
systemctl daemon-reload
systemctl enable etcd.service && systemctl start etcd.service
```

## 驗證 etcd 集群
> 在 A 執行看看

```
$ ETCDCTL_API=3 etcdctl     --cacert=${CA}/etcd-ca.pem     --cert=${CA}/etcd.pem     --key=${CA}/etcd-key.pem     --endpoints="https://10.140.0.2:2379"     endpoint health
https://10.140.0.2:2379 is healthy: successfully committed proposal: took = 699.357µs
```
