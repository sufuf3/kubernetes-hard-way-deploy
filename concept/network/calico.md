# Calico

## Table of Contents


## 前言
Ref: https://docs.projectcalico.org/v2.6/reference/architecture/  

## 架構圖
![](https://docs.projectcalico.org/images/lifecycle/calicoctl_node.png)

## 核心元件

### Felix
#### Intro
  - A primary Calico agent daemon
  - runs on every machine
  - provides endpoints
  - responsible for programming routes and ACLs
  - provide the desired connectivity for the endpoints on that host

#### Tasks
- Interface Management
  - To get the kernel to correctly handle the traffic emitted by that endpoint
  - ensure the host responds to ARP requests from each workload with the MAC of the host
  - enable IP forwarding for interfaces
  - monitors for interfaces to appear and disappear 

- Route Programming
  - responsible for programming routes to the endpoints on its host into the Linux kernel FIB (Forwarding Information Base)
  - Ensure packets destined for those endpoints that arrive on at the host are forwarded accordingly

- ACL Programming
  - responsible for programming ACLs into the Linux kernel
  - only valid traffic can be sent between endpoints, and ensure that endpoints are not capable of circumventing Calico’s security measures.

- State Reporting
  - providing data about the health of the network
  - reports errors and problems with configuring its host
  - Data is written into etcd (to make it visible to other components and operators of the network)

### Orchestrator Plugin
#### Intro
- bind Calico more tightly into the orchestrator(e.g. OpenStack, Kubernetes)
- Allowing users to manage the Calico network
#### Tasks
- API Translation
  - have its own set of APIs for managing networks
  - translate those APIs into Calico’s data-model and then store it in Calico’s datastore

- Feedback
  - Examples include:
    - providing information about Felix liveness
    - marking certain endpoints as failed if network setup failed

### etcd
#### Intro
- uses etcd to provide the communication between components and as a consistent data store
- ensures Calico can always build an accurate network
- etcd is used to mirror information about the network to the other Calico components
- divided into two groups of machines:
  - core cluster
  - the proxies

#### Tasks
- Data Storage
  - Ensures: Calico network is always in a known-good state, while allowing for some number of the machines hosting etcd to fail or become unreachable.
- Communication
  - non-etcd components watch certain points in the keyspace to ensure that they see any changes that have been made, allowing them to respond to those changes in a timely manner.

### BIRD in Calico
- BGP client
- BGP Route Reflector

#### BGP client
- deploys a BGP client on every node (also hosts a Felix)
- BGP client: read routing state that Felix programs into the kernel and distribute it around the data center.
- Task
  - Route Distribution
    - When Felix inserts routes into the Linux kernel FIB(forwarding information base), the BGP client will pick them up and distribute them to the other nodes in the deployment.
    - Ensures traffic is efficiently routed around the deployment


#### BGP Route Reflector
- 大規模部署時使用
- 通過一個或者多個 BGP Route Reflector 來完成集中式的路由分發
- Task
  - Centralized Route Distribution


#### Intro BIRD
- Whole name: BIRD Internet Routing Daemon
- Ref: http://bird.network.cz/?get_doc&v=16&f=bird-1.html#ss1.1


## calico-node container
Ref: https://docs.projectcalico.org/v2.6/reference/architecture/components  

- key components:
  - Felix
  - BIRD
  - confd

- other components:
  - runit for logging (svlogd)
  - init (runsv) services

### key components
#### Calico **Felix** agent
- Felix’s primary job: to program routes and ACL’s on a workload host to provide desired connectivity to and from workloads on the host.
- programs interface information to the kernel for outgoing endpoint traffic.
- instructs the host to respond to ARPs for workloads with the MAC address of the host.

#### BIRD/BIRD6 internet routing daemon
- BIRD is an open source BGP client that is used to exchange routing information between hosts
- Ref: https://github.com/projectcalico/bird

#### **confd** templating engine
- monitors the etcd datastore for any changes to BGP configuration (and some top level global default configuration such as AS Number, logging levels, and IPAM information).
- Confd dynamically generates BIRD configuration files based on the data in etcd, triggered automatically from updates to the data.
- https://github.com/projectcalico/confd


Ref:   
https://docs.projectcalico.org/v1.6/reference/without-docker-networking/docker-container-lifecycl  
http://blog.kubernetes.io/2016/10/kubernetes-and-openstack-at-yahoo-japan.htmle  
