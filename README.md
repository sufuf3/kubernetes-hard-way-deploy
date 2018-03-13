# 手把手安裝 v1.8.8 Kubernetes cluster 練習筆記

本篇是純手工安裝 Kubernetes 的練習筆記，並沒有使用自動安裝的工具來進行。  
目標是能了解 Kubernetes 的元件是怎麼組成並搭建起來。

## Table of Contents

- [練習環境(目前版本，可能會調整)](#%E7%B7%B4%E7%BF%92%E7%92%B0%E5%A2%83%E7%9B%AE%E5%89%8D%E7%89%88%E6%9C%AC%E5%8F%AF%E8%83%BD%E6%9C%83%E8%AA%BF%E6%95%B4)
- [架構簡介](#%E6%9E%B6%E6%A7%8B%E7%B0%A1%E4%BB%8B)
- [主要參考來源](#%E4%B8%BB%E8%A6%81%E5%8F%83%E8%80%83%E4%BE%86%E6%BA%90)
- [Kubernetes 學習]()

## 練習環境(目前版本，可能會調整)
- OS: Ubuntu 16.04
- kubernetes: v1.8.8
- etcd: v3.2.9
- Go: v1.8.4

## 架構簡介
一台 Master Node，兩台 Worker Node

## Kubernetes 學習
- [Objects](objects/)
- [核心元件](component/core/)

## 安裝參考來源
- https://kubernetes.io/
- https://github.com/kelseyhightower/kubernetes-the-hard-way
- https://www.gitbook.com/book/feisky/kubernetes/details
- https://jimmysong.io/kubernetes-handbook/
- https://kairen.github.io/2017/10/27/kubernetes/deploy/manual-v1.8/

## 學習參考資源
- https://kubernetes.io/
- https://k8smeetup.github.io/docs/home/
- https://jimmysong.io/kubernetes-handbook/
- https://www.gitbook.com/book/feisky/kubernetes/details
