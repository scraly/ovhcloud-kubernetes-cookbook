# Tips / FAQ

# NTP configuration

On MKS Nodes, NTP is configured with following servers:

```bash
[Time]
NTP=ntp.ovh.net ntp.ubuntu.com
```

## What happens when changing the "Plugin Always Pull Images" admission plugin parameter?

Only the api-server of a cluster is restarted, without data loss. It's an API server redeployment, not a cluster reset 🙂.