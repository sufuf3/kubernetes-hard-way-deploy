# CNI 學習筆記

> 參考以下三個資料來源做的筆記
> 1. https://github.com/containernetworking/cni/blob/master/README.md
> 2. https://github.com/containernetworking/cni/blob/master/SPEC.md
> 3. http://www.dasblinkenlichten.com/understanding-cni-container-networking-interface/
> 
> Ref: https://jimmysong.io/kubernetes-handbook/concepts/cni.html

## 簡介

CNI 全名 Container Network Interface，關注 containers 的網路資源使用，containers 起來就配網路給它，containers 死掉就回收網路資源。  
- CNI 包含 
    - specification
    - libraries for writing plugins (在 Linux containers 中 專門設定網路 interfaces)

## 如何使用？
- kubernetes 如果是用工具安裝，通常會將 cni 的 binary 檔放在 `/opt/cni/bin/` 底下的這些檔案都是從 https://github.com/containernetworking/cni/releases 的 cni-amd64-vx.x.x.tgz 解壓縮而來的。
- 網路設定檔(netconf file)都是放在 `/etc/cni/net.d`
  
自己用 [linux network namespace](http://man7.org/linux/man-pages/man8/ip-netns.8.html) 玩 CNI 的參考  
- https://medium.com/@john.lin/container-networking-interface-%E5%85%A5%E9%96%80%E7%B0%A1%E4%BB%8B-f48cfd818259
- http://www.dasblinkenlichten.com/understanding-cni-container-networking-interface/

## CNI 的 command 和網路設定檔
### 網路設定檔
- The network configuration is in JSON format
eg.  
```js
$ cat >/etc/cni/net.d/10-mynet.conf <<EOF
{
    "cniVersion": "0.2.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.22.0.0/16",
        "routes": [
            { "dst": "0.0.0.0/0" }
        ]
    }
}
EOF
```

### CNI command
eg.  
```
$ CNI_COMMAND=ADD CNI_CONTAINERID=ns1 CNI_NETNS=/var/run/netns/ns1 CNI_IFNAME=eth3 CNI_PATH=`pwd` ./bridge <mybridge.conf
```

## 使用 CNI 的 4 種方法
https://github.com/containernetworking/cni/blob/master/libcni/api.go#L51-L57  
- Add container to network (AddNetwork)
- Delete container from network (DelNetwork)
- AddNetworkList
- DelNetworkList

## 可用的 CNI plugin
https://github.com/containernetworking/plugins#plugins-supplied  

## Kubernetes with CNI
因為 kubernetes 不是用 ip netns ，所以需要多用幾個工具來看  
不過我們知道 Network namespace 的路徑是 `/proc/<PID>/ns/net`，所以我們只要找出 pod 的 PID 就好。  
第一步：使用 kubernetes 的指令拿 containerID  
第二步：使用 docker command 找出 PID  
第三步：用 `nsenter -t ${PID} -n ip addr` 指令就可以跑出類似 `ip netns exec ns1 ip addr` 的結果囉！  
  
參考：https://thenewstack.io/hackers-guide-kubernetes-networking/  
PS1. kubernetes 把原本手動收入 CNI command 的加入部分，寫到程式裡了 https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/dockershim/network/cni/cni.go#L26i  
PS2. 下一個要好好看研究 CNI plugin 部分，研究`/etc/cni/net.d` 的 network configuration 與寫 `/opt/cni/bin/` 底下的 binary 檔是最重要的。  
  
Ref: https://www.slideshare.net/hongweiqiu/introduction-to-cni-container-network-interface  
  
To be continue...  


