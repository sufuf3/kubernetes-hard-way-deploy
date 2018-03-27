# Ceph

- Ceph’s foundation is the Reliable Autonomic Distributed Object Store (RADOS)
- provides your applications with object, block, and file system storage in a single unified storage cluster
- A Ceph Storage Cluster requires at least one Ceph Monitor, Ceph Manager, and Ceph OSD 
    - Monitors: A Ceph Monitor (ceph-mon) maintains maps of the cluster state, including the monitor map, manager map, the OSD map, and the CRUSH map. These maps are critical cluster state required for Ceph daemons to coordinate with each other. Monitors are also responsible for managing authentication between daemons and clients.
    - Managers: A Ceph Manager daemon (ceph-mgr) is responsible for keeping track of runtime metrics and the current state of the Ceph cluster, including storage utilization, current performance metrics, and system load. The Ceph Manager daemons also host python-based plugins to manage and expose Ceph cluster information, including a web-based dashboard and REST API.
    - Ceph OSDs(Object Storage Daemon): A Ceph OSD (object storage daemon, ceph-osd) stores data, handles data replication, recovery, rebalancing, and provides some monitoring information to Ceph Monitors and Managers by checking other Ceph OSD Daemons for a heartbeat.
    - MDSs: A Ceph Metadata Server (MDS, ceph-mds) stores metadata on behalf of the Ceph Filesystem (i.e., Ceph Block Devices and Ceph Object Storage do not use MDS). Ceph Metadata Servers allow POSIX file system users to execute basic commands (like ls, find, etc.) without placing an enormous burden on the Ceph Storage Cluster.

## Deploy
[Ceph_deploy](Ceph_deploy.md)

Ref:  
- http://docs.ceph.com/docs/master/
- http://docs.ceph.org.cn/
