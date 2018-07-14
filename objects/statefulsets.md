# StatefulSet

> Ref: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/  

## 目標
- be used with stateful applications and distributed systems
- StatefulSet maintains a sticky identity for each of their Pods. 
- has a persistent identifier 
- StatefulSet controller makes any necessary updates to get there from the current state.

## 如果 App 是需要以下的需求，就會需要用到 statefulset
- Stable, unique network identifiers.
- Stable, persistent storage.
- Ordered, graceful deployment and scaling.
- Ordered, graceful deletion and termination.
- Ordered, automated rolling updates.
> stable is synonymous with persistence across Pod (re)scheduling.

## Using
- 必須根據請求由 PersistentVolume Provisioner 配置 or pre-provisioned by an admin 給定 Pod 的存儲
- 為了確保 data 安全，刪除和/或縮放 StatefulSet 將不會刪除與 StatefulSet 關聯的 volumes。
- StatefulSets currently require a Headless Service to be responsible for the network identity of the Pods. 我們有責任要先 create 這個 service 。

## 相關整理
- 會盡可能的在不同的節點上進行
- 依序啟動與刪除管理的 Pod (LIFO)
- 自動為 Pod 帶入編號 (0, 1, 2, ...)
- 使用 Volume template 會自動建立對應編號
- 支援 rolling upgrade

## Try
### Create
- yaml file
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx2
  labels:
    app: nginx2
spec:
  ports:
  - port: 80
    name: web2
  clusterIP: None
  selector:
    app: nginx2
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web2
spec:
  selector:
    matchLabels:
      app: nginx2 # has to match .spec.template.metadata.labels
  serviceName: "nginx2"
  replicas: 2 # by default is 1
  template:
    metadata:
      labels:
        app: nginx2 # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx2
        image: k8s.gcr.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web2
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "my-storage-class"
      resources:
        requests:
          storage: 1Gi
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: my-storage-class
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: "true"
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
provisioner: kubernetes.io/host-path
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: nginx2-pv-volume
  labels:
    type: local
spec:
  storageClassName: my-storage-class
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/tmp/data"
---
kind: PersistentVolume
apiVersion: v1
metadata:
  name: nginx22-pv-volume
  labels:
    type: local
spec:
  storageClassName: my-storage-class
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/tmp/data1"
```
- Result
```sh
$ kubectl get sts -o wide
NAME      DESIRED   CURRENT   AGE       CONTAINERS   IMAGES
web2      2         2         1h        nginx2       k8s.gcr.io/nginx-slim:0.8

$ kubectl get svc -o wide
nginx2       ClusterIP   None           <none>        80/TCP         1h        app=nginx2

$ kubectl get po -o wide
web2-0                   1/1       Running   0          1h        10.244.2.4   k8s-n2
web2-1                   1/1       Running   0          9m        10.244.1.4   k8s-n1

$ kubectl get pv,pvc -o wide
NAME                                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                STORAGECLASS       REASON    AGE
persistentvolume/nginx2-pv-volume    10Gi       RWO            Retain           Bound     default/www-web2-0   my-storage-class             10m
persistentvolume/nginx22-pv-volume   10Gi       RWO            Retain           Bound     default/www-web2-1   my-storage-class             9m

NAME                               STATUS    VOLUME              CAPACITY   ACCESS MODES   STORAGECLASS       AGE
persistentvolumeclaim/www-web2-0   Bound     nginx2-pv-volume    10Gi       RWO            my-storage-class   1h
persistentvolumeclaim/www-web2-1   Bound     nginx22-pv-volume   10Gi       RWO            my-storage-class   10m
```

### Scaling Up
```sh
$ kubectl scale sts web2 --replicas=5
```

### Cascading Delete
```sh
$ kubectl delete statefulset web2
$ kubectl delete service nginx2
```

More:  
- https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/  
- https://kubernetes.io/docs/tutorials/stateful-application/cassandra/  

