# 04. 設定與啟用 Secret data

## Table of Contents
- [前言](#%E5%89%8D%E8%A8%80)
- [建立加密密鑰](#%E5%BB%BA%E7%AB%8B%E5%8A%A0%E5%AF%86%E5%AF%86%E9%91%B0)
- [加密配置設定](#%E5%8A%A0%E5%AF%86%E9%85%8D%E7%BD%AE%E8%A8%AD%E5%AE%9A)
- [複製 encryption-config.yaml 到有 etcd 的 master node 上](#%E8%A4%87%E8%A3%BD-encryption-configyaml-%E5%88%B0%E6%9C%89-etcd-%E7%9A%84-master-node-%E4%B8%8A)

## 前言
一般情况下，etcd 包含了通過 Kubernetes API 可以拿到所有資料，可以讓授予 etcd 的使用者對 cluster 進行攻擊。  
因此需要來對這些資料進行加密。  
k8s 使用 rest 加密機制，它是 α 特性，会加密 etcd 裡面的 Secret 資源，以防止某一方通過查看这些 secret 的内容獲得 etcd 的備份。  
所以這邊要來設定與啟用 rest 加密 etcd 中的 secret data 的機制。

Ref:  
https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/  
https://k8smeetup.github.io/docs/tasks/administer-cluster/securing-a-cluster/  


## 建立加密密鑰
Generate a 32 byte random key and base64 encode it.  
```
$ head -c 32 /dev/urandom | base64
1rxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkk
```

## 加密配置設定
- 新增 encryption-config.yaml 檔案

```
vim /etc/kubernetes/encryption-config.yaml
```

- 編輯內容

```yaml
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: 1rxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkk
      - identity: {}
```

## 複製 encryption-config.yaml 到有 etcd 的 master node 上
複製 /etc/kubernetes/encryption-config.yaml 到 A~C

Memo: 記得要在等等的 kube-apiserver 中加上 `--experimental-encryption-provider-config` 的設定  

