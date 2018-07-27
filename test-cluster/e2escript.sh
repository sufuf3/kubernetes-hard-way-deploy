mkdir ~/itri-e2e

cat << EOF >> ~/.bashrc
alias stripcolors='sed "s/\x1B\[\([0-9]\{1,2\}\(;[0-9]\{1,2\}\)\?\)\?[mGK]//g"'
EOF

source ~/.bashrc

cd ~/go/src/k8s.io/kubernetes && GINKGO_PARALLEL=y go run hack/e2e.go -- --provider=skeleton --build --up --test --test_args="--ginkgo.focus=\[Conformance\] --ginkgo.skip=\[(Serial|It|Flaky|Slow|sig-scheduling|sig-cli|sig-network|Feature:.*)\]" --dump  --down| tee -a ~/itri-e2e/itri-test.log

echo -ne "$(cat ~/itri-e2e/itri-test.log)" | stripcolors >> ~/itri-e2e/e2e.log

cd ~/ && zip -r ~/itri-e2e/itri-log ~/go/src/k8s.io/kubernetes/--down/

echo 'Please checkout host_ip:8089 and download the files for e2e test result!'
cd ~/itri-e2e/ && python -m SimpleHTTPServer 8089

