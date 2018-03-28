# Nodes

Node 是 kubernetes cluster 的 work node，可以是實體機也可以是虛擬機。

驅逐該 node 上的所有 pod
```sh
$ kubectl drain <node>
```
維護完 node 後，告訴 master 這個節點已經可以來讓 pod 進駐了。
```sh
$ kubectl uncordon <node>
```


Ref:  
- https://kubernetes.io/docs/concepts/architecture/nodes/
- https://k8smeetup.github.io/docs/concepts/architecture/nodes/
- https://jimmysong.io/kubernetes-handbook/concepts/node.html
