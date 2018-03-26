# etcd

- Written in Go
- A distributed key value store
- provides a reliable way to store data across a cluster of machines.
- handles leader elections during network partitions and will tolerate machine failure, including the leader.
- Communication between etcd machines is handled via the Raft consensus algorithm.

![](https://i.imgur.com/xviMp3P.png)  
![](https://cdn-images-1.medium.com/max/1600/0*c2N7STjiWZjCy8we.png)

Ref:  
- https://www.youtube.com/watch?v=hQigKX0MxPw  
- https://godoc.org/github.com/coreos/etcd/raft  
- http://www.infoq.com/cn/articles/coreos-analyse-etcd  
- https://medium.com/jorgeacetozi/kubernetes-master-components-etcd-api-server-controller-manager-and-scheduler-3a0179fc8186
---

### Raft: The Understandable Distributed Consensus Protocol
Ref:   
- https://speakerdeck.com/benbjohnson/raft-the-understandable-distributed-consensus-protocol/
- https://raft.github.io/

#### Raft
- A consensus algorithm
- Defines three different roles (Leader, Follower, and Candidate) and achieves consensus via an elected leader.

#### what is consensus
- Consensus involves multiple servers agreeing on values.
- Typical consensus algorithms make progress when any majority of their servers is available
- Eg. A cluster of 5 servers can continue to operate even if 2 servers fail. If more servers fail, they stop making progress (but will never return an incorrect result).
- A general approach to building fault-tolerant systems.
- Each server has a state machine and a log
    - state machine
        - fault-tolerant component
        - Each state machine takes as input commands from its log
