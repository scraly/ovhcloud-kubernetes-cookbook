# Load Balancer

MKS <1.31: IOLB by default.
MKS 1.31+: Public Cloud Load Balancer by default.

## Get the real source IP

By default, when deploying services through a LoadBalancer, the LB act as a proxy, so the remote address of an application will be the IP of the LB, not the client/source IP of the request.

The solution is to preserve the source IP.

Prerequisites: deploy an [Ingress Controller](../ingress/README.md).

### Get the list of the egress load balancer IPs

For `ingress-nginx`:

#### [PUBLIC NETWORK ONLY]

For IOLB:
```bash
$ EGRESS_IPS=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.metadata.annotations.lb\.k8s\.ovh\.net/egress-ips}")
$ echo $EGRESS_IPS
```

For Public Cloud Load Balancer:
```bash
$ EGRESS_IPS=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.metadata.annotations.loadbalancer\.ovhcloud\.com/egress-ips}")
$ echo $EGRESS_IPS
```

#### [PRIVATE NETWORK ONLY]

When your Managed Kubernetes cluster is attached to a vRack, load balancers will take two random IP addresses each. Your egress IP list is your subnet range.

Copy/paste your subnet range in an `EGRESS_IPS` environment variable:

```bash
EGRESS_IPS=xx.xx.xx.xx/xx
```

### Patch manifest files

Copy the next YAML snippet in a `patch-ingress-controller-service.yml` file:

For IOLB:
```yaml
metadata:
    annotations:
      # For Managed Kubernetes Service version < 1.31
      service.beta.kubernetes.io/ovh-loadbalancer-proxy-protocol: "v2"
spec:
  externalTrafficPolicy: Local
```

For Public Cloud Load Balancer:
```yaml
metadata:
    annotations:
      # For Managed Kubernetes Service version >= 1.31
      loadbalancer.openstack.org/proxy-protocol : "v2"
spec:
  externalTrafficPolicy: Local
```

Patch:
```bash
kubectl -n ingress-nginx patch service ingress-nginx-controller -p "$(cat patch-ingress-controller-service.yml)"
```

Copy the next YAML snippet in a `patch-ingress-controller-configmap.yml` file:

```yaml
data:
  use-proxy-protocol: "true"
  real-ip-header: "proxy_protocol"
  proxy-real-ip-cidr: "$EGRESS_IPS"
```

Apply:
```bash
kubectl -n ingress-nginx patch configmap ingress-nginx-controller -p "$(cat patch-ingress-controller-configmap.yml)"
```

Due to DNS propagation the actual resolving of your Load Balancer FQDN can take an additional 2-5 minutes to be fully usable. In the meantime, you can use the included IP to access the load balancer.
The domain name generated for the service displayed in the `EXTERNAL-IP` fields is for cluster internal usage only. It should not be used to access the service from internet. 