# Kubernetes resource types lists (objects)

## Valid resource types include

- [ ] certificatesigningrequests (aka 'csr')
- [ ] clusterrolebindings
- [ ] clusterroles
- [ ] componentstatuses (aka 'cs')
- [ ] configmaps (aka 'cm')
- [ ] controllerrevisions
- [ ] cronjobs
- [ ] customresourcedefinition (aka 'crd')
- [ ] daemonsets (aka 'ds')
- [ ] deployments (aka 'deploy')
- [ ] endpoints (aka 'ep')
- [ ] events (aka 'ev')
- [ ] horizontalpodautoscalers (aka 'hpa')
- [ ] ingresses (aka 'ing')
- [ ] jobs
- [ ] limitranges (aka 'limits')
- [ ] namespaces (aka 'ns')
- [ ] networkpolicies (aka 'netpol')
- [ ] nodes (aka 'no')
- [ ] persistentvolumeclaims (aka 'pvc')
- [ ] persistentvolumes (aka 'pv')
- [ ] poddisruptionbudgets (aka 'pdb')
- [ ] podpreset
- [ ] pods (aka 'po')
- [ ] podsecuritypolicies (aka 'psp')
- [ ] podtemplates
- [ ] replicasets (aka 'rs')
- [ ] replicationcontrollers (aka 'rc')
- [ ] resourcequotas (aka 'quota')
- [ ] rolebindings
- [ ] roles
- [ ] secrets
- [ ] serviceaccounts (aka 'sa')
- [x] services (aka 'svc')  -- Doing
- [ ] statefulsets (aka 'sts')
- [ ] storageclasses (aka 'sc')

```sh
$ kubectl get -h
```
https://github.com/kubernetes/kubernetes/blob/master/pkg/printers/internalversion/describe.go#L127-L163  
