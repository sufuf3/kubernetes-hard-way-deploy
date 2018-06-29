# Kuberentes End to end (e2e) Testing
- 測試系統 end-to-end 行為
- 確保 end user 操作符合開發人員規格

- 主要目標:
    - ensure a consistent and reliable behavior of the kubernetes code base
    - to catch hard-to-test bugs before users do, when unit and integration tests are insufficient

- The e2e tests in kubernetes are built atop of Ginkgo and Gomega.
> Ginkgo is a golang testing framework
> Gomega is a matcher/assertion library. It is best paired with the Ginkgo BDD test framework, but can be adapted for use in other contexts too.

## Install
First of all, please install golang, you could refer from https://golang.org/doc/install.
1. Install [ginkgo](https://github.com/onsi/ginkgo)
```sh
$ go get -u github.com/onsi/ginkgo/ginkgo  # installs the ginkgo CLI
$ go get -u github.com/onsi/gomega/...     # fetches the matcher library
```
2. Get kubernetes source code & checkout the version you installed before.
```sh
$ go get -u github.com/kubernetes/kubernetes'
$ cd go/src/github.com/kubernetes/kubernetes
$ git checkout v1.10.2
```
3. Compile the test file
```sh
$ make WHAT='test/e2e/e2e.test'
$ make ginkgo
$ export KUBERNETES_PROVIDER=local
$ export KUBECONFIG=~/.kube/config
$ export KUBERNETES_CONFORMANCE_TEST=y
$ export KUBECTL_PATH=/usr/local/bin/kubectl
$ export KUBE_MASTER_IP="10.223.5.200:6443"
$ export KUBE_MASTER=10.223.5.200
```
## Run tests
https://github.com/kubernetes/community/blob/master/contributors/devel/e2e-tests.md#building-kubernetes-and-running-the-tests
- example
```
$ GINKGO_PARALLEL=y go run hack/e2e.go -- --provider=skeleton  --build --up --test --test_args="--ginkgo.focus=\[Conformance\] --ginkgo.skip=\[Serial\]" --down

$ GINKGO_PARALLEL=y go run hack/e2e.go -- --provider=skeleton --build --up --test --test_args="--ginkgo.focus=\[Conformance\] --ginkgo.skip=\[Slow\] --delete-namespace-on-failure=false" --down | tee -a tmp0629.log
```

<!--## Try
- https://github.com/sufuf3/kubernetes-e2e
- like
```sh
Ran 155 of 852 Specs in 3435.885 seconds
FAIL! -- 134 Passed | 21 Failed | 0 Pending | 697 Skipped
```-->

## Ref
- https://supereagle.github.io/2017/03/09/kubemark/
- https://jimmysong.io/kubernetes-handbook/develop/testing.html
- https://github.com/mikkeloscar/kubernetes-e2e
- https://jimmysong.io/kubernetes-handbook/practice/network-and-cluster-perfermance-test.html
- https://godoc.org/k8s.io/kubernetes/test/e2e
- https://github.com/kubernetes/kubernetes/tree/master/test/e2e
- https://github.com/kubernetes/community/blob/master/contributors/devel/e2e-tests.md
- https://github.com/kubernetes/test-infra/tree/master/kubetest
- https://caylent.com/50-useful-kubernetes-tools/#Test
