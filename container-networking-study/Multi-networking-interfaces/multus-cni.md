# Multus-cni Note

> Refer from 
> 1. https://builders.intel.com/docs/networkbuilders/multiple-network-interfaces-in-kubernetes-application-note.pdf
> 2. https://github.com/Intel-Corp/multus-cni

##  Introduction
![](https://i.imgur.com/ZIuPSkv.png)
Kubernetes networking before and after Multus

## Multiple networking interfaces using Multus
- Multus + other CNI plugins
    - Multus: behaves as a broker and arbiter of other CNI plugins
    - other CNI plugins: as master plugin, is used to configure and manage the primary network interface (eth0)

**Multus workflow in Kubernetes**
![](https://i.imgur.com/srL4I6K.png)

Multus為每個 delegates (CNI plugins & 他們相對應的配置 - Network plugin 的部分)引入 delegateAdd()，接著 Multus 讓 delegate 呼叫自己的 cmdAdd() 加 network interface 到 pod.
The arguments of these delegate CNI plugins can be stored as CRD or TPR object in Kubernetes

NFV Data plane
- SR-IOV
- Data Plane Development Kit(DPDK)

## Improving network performance using Multus and SR-IOV/DPDK
SR-IOV CNI plugin 可以允許 Kubernetes pod 直接 attach 到 SR-IOV virtual function (VF) in one of two modes.
- The first mode: 使用標準的 SR-IOV VF driver in the container host’s kernel. 
- The second mode: 支援 DPDK VNFs that execute the VF driver and network protocol stack in user space. 
### DPDK
#### 英文整理
- collection of libraries and drivers
    - support fast-packet processing by routing packets around the OS kernel 
    - minimizing the number of CPU cycles needed to send and receive packets. 
- DPDK libraries include multicore framework, huge page memory, ring buffers and poll mode drivers for networking and other network functions.
- www.dpdk.org
#### 中文 google
- DPDK 全名 Data Plane Development Kit
- 提升封包處理效能與傳輸量
- 可讓資料層面應用程式有充裕的處理時間
- Ref:　
    - https://builders.intel.com/university/networkbuilders/coursescategory/dpdk
    - https://feisky.gitbooks.io/sdn/dpdk/

### SR-IOV
#### 英文整理
-  a PCI-SIG standardized method for isolating PCI Express (PCIe) native hardware resources for manageability and performance reasons.
-  a single PCIe device, referred to as the physical function (PF), can appear as multiple separate PCIe devices, referred to as virtual functions (VF)

- SR-IOV-enabled network interface card (NIC)
    - each VFs MAC and IP address can be independently configured and packet switching between the VFs occurs in the device hardware

#### 中文 google

- SR-IOV 全名 Single Root I/O Virtualization and Sharing Specification
- 基於硬體的虛擬化解決方案
- 兩個功能類型：
    - 物理功能（Physical Functions，PFs）：這是一些支持 SR-IOV 擴展功能的 PCIe 功能，被用於配置和管理SR-IOV功能特性
    - 虛擬功能（Virtual Functions，VFs）：這是一些「精簡」的 PCIe 功能，包括數據遷移必需的資源，以及經過謹慎精簡的配置資源集
- Ref: http://b8807053.pixnet.net/blog/post/345974548-sr-iov-%E7%B0%A1%E4%BB%8B




### Using Multus and SR-IOV/DPDK

![](https://i.imgur.com/Tkvyf5j.png)


- eth0: k8s 的管理介面 (control plane for k8s cluster)
- net0 & net1: data plane

VLAN is implemented between the virtual firewall and the 802.1Q switches and routers  
The firewall recognizes VLAN IDs, and applies the firewall rules specific to each VLAN  
This can include authenticating data or applying relevant policies established in the data plane network  

## 1. Configuring Multus in Kubernetes
-  two Multus configuration options for selecting networks in Kubernetes:
    - A. Configure Multus using network objects with default network
    - B. Configure Multus using config file
### A. Configure Multus using network objects
Using vFirewall  
Flannel, SR-IOV, SR-IOV + VLAN  
- Custom resource definition (CRD): offers a simple way to create custom resources.
    - a facility to describe a new API entity to the Kubernetes API server. 
    - Third Party Resource (TPR)
    -  provides a stable object with the introduction to new features such as pluralization of resource names and the ability to create non-namespaced CRDs

![](https://i.imgur.com/0HRpogr.png)

Multus is compatible with both CRD and TPR extension objects.  
TPR 只支援到 k8s v1.7 ，新的只支援 CRD-based objects   


- Install Go-lang
```sh
$ sudo add-apt-repository ppa:longsleep/golang-backports
$ sudo apt-get update
$ sudo apt-get install golang-go
```
- Add Multus plugin
```sh
$ git clone https://github.com/intel/multus-cni.git
$ cd multus-cni
$ ./build
```
#### 1. Defining CRD-based network objects


#### 2. How to create network objects
- Creating network resources in Kubernetes

### B. Configure Multus using config file

### Verifying pod networks

## 2. Configuring SR-IOV/DPDK in Kubernetes


## Try
https://github.com/sufuf3/Multus-with-k8s  

## Software 
Ubuntu 16.04.2 x86_64 (Server)  
Kernel: 4.4.0-62-generic  
NIC Kernel Drivers: i40e v2.0.30, i40evf v2.0.30  
DPDK 17.05 (Software download): http://fast.dpdk.org/rel/dpdk-17.05.tar.xz  
CMK: v1.1.0 & v1.2.1 - https://github.com/Intel-Corp/CPU-Manager-for-Kubernetes  
SR-IOV-CNI: v0.2-alpha. commit ID: a2b6a7e03d8da456f3848a96c6832e6aefc968a6  
https://www.ubuntu.com/download/server  
