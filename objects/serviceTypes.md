# Service

## Table of Contents
- [Defining a service](#defining-a-servise)
- [Virtual IPs and service proxies](#virtual-ips-and-service-proxies)
- [Publishing services - service types](#publishing-services---service-types)
    - [Type NodePort](#type-nodeport)
    - [Type LoadBalancer](#type-loadbalancer)

## Defining a service
- Service is an abstraction which defines a logical set of Pods and a policy by which to access them - sometimes called a micro-service. 
- Service 會指定一個 IP 預設是 Cluster IP。
- Service 在 Spec 內有可以有或沒有 selector
    - 有 selector 則可以讓 client/user 可以定義一組 objects 。
    - 差別在於會不會自動建立相關的 Endpoints object
        - selector 會自動建 endpoints；沒有 selector 不會自動建立，不過可以再用 kind 為 Endpoints 就可以建立。


## Virtual IPs and service proxies
To be continue...  

## Publishing services - service types
為 Type 的值。分為 4 種 type。

### Type ClusterIP
ClusterIP：為預設的 ServiceType 。該 service 只能透過這個 service IP 在 cluster 內部 access 。  
除非使用 Kubernetes Proxy ，要不然根本不能從 cluster 外連到這個服務唷！  
透過由 google-cloud 的 medium blog 提供的下圖，可以看到如果要從外部訪問這個 service 都是要透過 proxy 才可以 access 到這個 service 。  
(**自我好記的解釋：如字面上的意思，要 access 我這個 service 就在 cluster 內吧！直接用我這個 service 的 cluster IP 來 access 我吧！**)
![](https://cdn-images-1.medium.com/max/800/1*I4j4xaaxsuchdvO66V3lAg.png)

### Type NodePort
NodePort：這個是使用 node 的 IP 和 node 的 port 來讓外埠存取這個 service 。 也就是使用 `<NodeIP>:<NodePort>` 來達到 access 該 service 的目的。  
如果要指定 port ，可以在 yaml 中加上 nodePort 來指定 port(range 是 30000-32767)。  
(**自我好記的解釋：如字面上的意思，就是使用 node 的 port。**)
![](https://cdn-images-1.medium.com/max/800/1*CdyUtG-8CfGu2oFC5s0KwA.png)  

### Type LoadBalancer
Exposes the service externally using a cloud provider’s load balancer.  
依據這篇討論 https://github.com/kubernetes/ingress-nginx/issues/691  這個方法不建議使用。先不探討。  
![](https://cdn-images-1.medium.com/max/800/1*P-10bQg_1VheU9DRlvHBTQ.png)  

### Type ExternalName
Maps the service to the contents of the externalName field (e.g. foo.bar.example.com), by returning a CNAME record with its value. No proxying of any kind is set up. This requires version 1.7 or higher of kube-dns.

Ref:  
1. https://kubernetes.io/docs/concepts/services-networking/service  
2. https://k8smeetup.github.io/docs/concepts/services-networking/service/  
3. https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0  
