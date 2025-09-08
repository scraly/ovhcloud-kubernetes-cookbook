# Tips / FAQ

# NTP configuration

On MKS Nodes, NTP is configured with following servers:

```bash
[Time]
NTP=ntp.ovh.net ntp.ubuntu.com
```

## What happens when changing the "Plugin Always Pull Images" admission plugin parameter?

Only the api-server of a cluster is restarted, without data loss. It's an API server redeployment, not a cluster reset 🙂.

## How to connect to a node in a MKS?

Install and use the kubectl plugin [node-shell](https://github.com/kvaps/kubectl-node-shell).

```bash
kubectl get no
kubectl node-shell <my-node>
```

## Pubic to Private MKS cluster

⚠️ A MKS Public cluster (public only) can't be transformed into a MKS Private cluster.
Solution: create a MKS private cluster + backup/restore.