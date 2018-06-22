# Try everything
```
#!/bin/bash

export KUBECONFIG=/etc/kubernetes/kubectl.kubeconfig
export KUBERNETES_CONFORMANCE_TEST=y
export KUBECTL_PATH=/usr/bin/kubectl
export KUBERNETES_PROVIDER=local
export KUBE_ROOT=/home/go/src/k8s.io/kubernetes

GINKGO_PARALLEL=y go run /home/go/src/k8s.io/kubernetes/hack/e2e.go --v --root=$KUBE_ROOT --test --test_args="--ginkgo.focus=\[Conformance\] --ginkgo.skip=\[Serial\]"
#go run /home/go/src/k8s.io/kubernetes/hack/e2e.go --v --root=$KUBE_ROOT --test --test_args="--ginkgo.focus=\[Serial\].*\[Conformance\]"
```
- https://developer.ibm.com/opentech/2016/06/15/kubernetes-developer-guide-part-1/
- http://blog.michali.net/2017/05/30/end-to-end-testing/
- https://godoc.org/k8s.io/kubernetes/test/e2e
