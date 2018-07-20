# Kubernetes Scheduler

## 參考資料
- https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/
- https://github.com/kubernetes/community/blob/master/contributors/devel/scheduler.md
- https://github.com/kubernetes/community/blob/master/contributors/devel/scheduler_algorithm.md
- https://github.com/jamiehannaford/what-happens-when-k8s#scheduler

## 概念
當 controller running 後，pod 是在 pending 狀態，因為他們還沒在 node 上被 create。所以 kubernetes 的 schedular 就是在調度 pod 這件事。  
他是 control plane 的 component ，他會監聽 Event 並常是協調狀態。  
Default scheduling algorithm 是  
1. 註冊一個 chain of default predicates 。predicates 是一個有效的功能，它評估時，會根據節點託管節點的適用性來過濾節點。(例如， pod 說他要多少的 CPU/RAM 等資源，然後發現 nodeA 資源不足，就直接取消選擇該節點。經過這一個步驟，它會篩選出可以選擇的 nodes ，然後進入下一步驟。)如果發現沒有可用的資源，那就會取消 create pod，不會進入下一步驟。
2. 選擇了適當的節點後，會對這些節點進行一系列的 priority functions，進行試用性的排序。

選好節點後， scheduler 會 create 一個 Binding object (Name and UID match the Pod, ObjectReference field contains the name of the selected Node) 然後送一個 POST 的 request 給 APIserver。  
然後 APIserver 會更新 pod 的 `pod.Spec.NodeName`, `pod.Annotations`, `api.PodScheduled`==`True`  
之後，kubelet 會在那個 node 上 create pod。

## customising the scheduler
- predicate 和 priority functions 是可擴展的，可以使用 `--policy-config-file`

## Filtering the nodes
https://github.com/kubernetes/community/blob/master/contributors/devel/scheduler_algorithm.md#filtering-the-nodes  

## Ranking the nodes
https://github.com/kubernetes/community/blob/master/contributors/devel/scheduler_algorithm.md#ranking-the-nodes  

## threshold
```sh
The kubelet has the following default hard eviction threshold:

    memory.available<100Mi
    nodefs.available<10%
    nodefs.inodesFree<5%
    imagefs.available<15%
```
https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/  
https://k8smeetup.github.io/docs/tasks/administer-cluster/out-of-resource/  
