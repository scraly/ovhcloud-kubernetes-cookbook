# Customizing Kube-proxy

⚠️ Only for MKS clusters running the Canal/Calico CNI (not Cilium)!

The kube-proxy Kubernete's component (which runs on each Node and allows network communication to Pods) with iptables is actually a bottleneck to scale the cluster to a high number of Nodes so at OVHcloud we decided to reduce this bottleneck and allow you to use kube-proxy with IPVS (IP Virtual Server) mode.

[IPVS (IP Virtual Server)](https://kubernetes.io/blog/2018/07/09/ipvs-based-in-cluster-load-balancing-deep-dive/) is built on top of the Netfilter and implements transport-layer Load Balancing as part of the Linux kernel.

## Create a MKS cluster with IPVS instead of IPtablesIn Terraform/OpenTofu

```hcl
resource "ovh_cloud_project_kube" "my_cluster" {
  service_name    = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  name            = "my_kube_cluster"
  region          = "GRA11"
  kube_proxy_mode = "ipvs" # or "iptables"    

  customization_kube_proxy {
    iptables {
      min_sync_period = "PT0S"
      sync_period = "PT0S"
    }

    ipvs {
      min_sync_period = "PT0S"
      sync_period = "PT0S"
      scheduler = "rr"
      tcp_timeout = "PT0S"
      tcp_fin_timeout = "PT0S"
      udp_timeout = "PT0S"
    }
  }
}
```

Explanation:

* `customization_kube_proxy` - Kubernetes kube-proxy customization
** `iptables` - (Optional) Kubernetes cluster kube-proxy customization of iptables specific config (durations format is [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration, e.g. PT60S)
*** `sync_period` - (Optional) Minimum period that iptables rules are refreshed, in [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration format (e.g. PT60S).
*** `min_sync_period` - (Optional) Period that iptables rules are refreshed, in [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration format (e.g. PT60S). Must be greater than 0.

** `ipvs` - (Optional) Kubernetes cluster kube-proxy customization of IPVS specific config (durations format is [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration, e.g. PT60S)
*** `sync_period` - (Optional) Minimum period that IPVS rules are refreshed, in [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration format (e.g. PT60S).
*** `min_sync_period` - (Optional) Minimum period that IPVS rules are refreshed in [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration (e.g. PT60S).
*** `scheduler` - (Optional) IPVS scheduler.
*** `tcp_timeout` - (Optional) Timeout value used for idle IPVS TCP sessions in [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration (e.g. PT60S). The default value is PT0S, which preserves the current timeout value on the system.
*** `tcp_fin_timeout` - (Optional) Timeout value used for IPVS TCP sessions after receiving a FIN in [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration (e.g. PT60S). The default value is PT0S, which preserves the current timeout value on the system.
*** `udp_timeout` - (Optional) timeout value used for IPVS UDP packets in [RFC3339](https://www.rfc-editor.org/rfc/rfc3339) duration (e.g. PT60S). The default value is PT0S, which preserves the current timeout value on the system.

## Configure kube-proxy through the API

* Get an existing cluster's customization:

`GET /cloud/project/{serviceName}/kube/{kubeID}/customization`

```yaml
{
    "apiServer": {
      "admissionPlugins": {
        "disabled": [],
        "enabled": ["AlwaysPullImages", "NodeRestriction"]
      }
    },
    "kubeProxy": {
      "iptables": {
        "minSyncPeriod": "PT1S",
        "syncPeriod": "PT30S"
      },
      "ipvs": {
        "minSyncPeriod": "PT0S",
        "scheduler": "rr",
        "syncPeriod": "PT30S",
        "tcpFinTimeout": "PT0S",
        "tcpTimeout": "PT0S",
        "udpTimeout": "PT0S",
      }
    }
}
```

Both IPVS and iptables specific configuration can be set at the same time and kube-proxy will select the one to use according to the mode value.

* Editing the kube-proxy mode and reset a cluster

⚠️ kubeProxyMode cannot be modified, you need to reset your Kubernetes cluster.

Reset a Kubernetes cluster (all Kubernetes data will be erased (pods, services, configuration, etc), nodes will be either deleted or reinstalled)

`POST /cloud/project/{serviceName}/kube/{kubeID}/reset`

```yaml
{
    "region": "GRA5",
    "name": "my-super-cluster",
    "kubeProxyMode": "ipvs",
    "customization": {
      "kubeProxy":{
         "iptables":{
            "minSyncPeriod":"PT1S",
            "syncPeriod":"PT30S"
         },
         "ipvs":{
            "minSyncPeriod":"PT0S",
            "scheduler":"rr",
            "syncPeriod":"PT30S",
            "tcpFinTimeout":"PT0S",
            "tcpTimeout":"PT0S",
            "udpTimeout":"PT0S"
         }
      }
   }
}
```

💡 Both `kubeProxyMode` and `customization` fields can be modified on cluster reset with the same payload used for creation.
If these fields are not specified, it will reset to default value (ipvs for kubeProxyMode and empty customization).

* Update only `kubeProxy` and keep existing apiServer customization if any

⚠️ `kubeProxyMode` cannot be modified by updating an existing cluster, it can only be set on cluster creation and reset.

`PUT /cloud/project/{serviceName}/kube/{kubeID}/customization`

```yaml
{
    "kubeProxy": {
        "iptables": {
            "minSyncPeriod": "PT60S"
            "syncPeriod": "PT60S"
        }
    }
}
```
