# On master for k8s v1.10.2

# Install Golang
cd /home/$USER
curl -LO https://storage.googleapis.com/golang/go1.10.2.linux-amd64.tar.gz
sudo tar -zxf go1.10.2.linux-amd64.tar.gz -C /usr/local/
echo 'export GOROOT=/usr/local/go' >>  /home/$USER/.bashrc
echo 'export GOPATH=$HOME/go' >> /home/$USER/.bashrc
echo 'export PATH=/home/$USER/protoc/bin:$PATH:$GOROOT/bin:$GOPATH/bin' >> /home/$USER/.bashrc
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=/home/$USER/protoc/bin:$PATH:$GOROOT/bin:$GOPATH/bin

# setup golang dir
mkdir -p /home/$USER/go/src
rm -rf /home/$USER/go1.10.2.linux-amd64.tar.gz

# 
cd 
go get -u github.com/onsi/ginkgo/ginkgo
go get -u github.com/onsi/gomega/...|
# https://github.com/kubernetes/kubernetes#to-start-developing-kubernetes
go get -u k8s.io/kubernetes
go get -d k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes
# pwd for root /root/go/src/k8s.io/kubernetes
git checkout v1.10.2
yum install -y gcc
make WHAT='test/e2e/e2e.test'
make ginkgo
export KUBERNETES_PROVIDER=local
export KUBECONFIG=~/.kube/config
export KUBERNETES_CONFORMANCE_TEST=y
export KUBECTL_PATH=/usr/local/bin/kubectl
export KUBE_MASTER_IP="10.223.5.200:6443"
export KUBE_MASTER=10.223.5.200

GINKGO_PARALLEL=y go run hack/e2e.go -- --provider=skeleton  --build --up --test --test_args="--ginkgo.focus=\[Conformance\] --ginkgo.skip=\[Serial\]" --down
