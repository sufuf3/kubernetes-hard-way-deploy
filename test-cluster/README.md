# Kuberentes End to end (e2e) Testing
- 測試系統 end-to-end 行為
- 確保 end user 操作符合開發人員規格

- 主要目標:
    - ensure a consistent and reliable behavior of the kubernetes code base
    - to catch hard-to-test bugs before users do, when unit and integration tests are insufficient

- The e2e tests in kubernetes are built atop of Ginkgo and Gomega.
> Ginkgo is a golang testing framework
> Gomega is a matcher/assertion library. It is best paired with the Ginkgo BDD test framework, but can be adapted for use in other contexts too.

## Try
https://github.com/sufuf3/kubernetes-e2e

## Ref
- https://supereagle.github.io/2017/03/09/kubemark/
- https://jimmysong.io/kubernetes-handbook/develop/testing.html
- https://github.com/mikkeloscar/kubernetes-e2e
- https://jimmysong.io/kubernetes-handbook/practice/network-and-cluster-perfermance-test.html
- https://godoc.org/k8s.io/kubernetes/test/e2e
- https://github.com/kubernetes/kubernetes/tree/master/test/e2e
- https://github.com/kubernetes/community/blob/master/contributors/devel/e2e-tests.md
