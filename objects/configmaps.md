# ConfigMap

- ConfigMap 用來儲存文件，是 kubernetes 資源對象，所有的配置內容都儲存在 etcd 中
- 可以把 ConfigMap 聯想成 Linux 中的 `/etc`目錄和它裡面的内容
- 必須在 Pod 使用 ConfigMap 之前，建立好 ConfigMap
- 如果使用了一個不存在的 ConfigMap， 便無法啟動這個 Pod
- 使用 ConfigMap 掛載的 Env 不會同步更新
- 使用 ConfigMap 掛載的 Volume 中的資料需要一段时间才會同步更新
- pod 使用 ConfigMap，通常用於：設定環境變數、設定命令列參數、創建配置文件。
- Options:
  -  `--from-env-file=''`: Specify the path to a file to read lines of key=val pairs to create a configmap (i.e. a Docker .env file).
  -  `--from-file=[]`: Key file can be specified using its file path, in which case file basename will be used as configmap key, or optionally with a key and file path, in which case the given key will be used.  Specifying a directory will iterate each named file in the directory whose basename is a valid configmap key.
  -  `--from-literal=[]`: Specify a key and literal value to insert in configmap (i.e. mykey=somevalue)

Ref:  
- https://jimmysong.io/kubernetes-handbook/concepts/configmap.html
- https://jimmysong.io/kubernetes-handbook/concepts/configmap-hot-update.html
- https://blog.csdn.net/liukuan73/article/details/79492374

