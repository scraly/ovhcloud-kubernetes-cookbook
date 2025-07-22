# Cluster AutoScaler

## Enabling the autoscaler

List existing node pools:
```bash
kubectl get np
```

Result:

```bash
$ kubectl get np
NAME             FLAVOR   AUTOSCALED   MONTHLYBILLED   ANTIAFFINITY   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   MIN   MAX   AGE
my-pool-zone-1   b3-8     false        false           false          3         3         3            3           0     100   2m45s
```

As you can see, the `AUTOSCALED` field is set to false. Let's see why by looking at the node pool description.

Let's check the node pool configuration:

```bash
$ kubectl get np my-pool-zone-1 -o json | jq .spec.autoscale
false

$ kubectl get np my-pool-zone-1 -o json | jq .spec.autoscaling
{
  "scaleDownUnneededTimeSeconds": 0,
  "scaleDownUnreadyTimeSeconds": 0,
  "scaleDownUtilizationThreshold": "0.00"
}
```

Enable autoscale for this node pool:

```bash
kubectl patch nodepool my-pool-zone-1 --type="merge" --patch='{"spec": {"autoscale": true}}'
```

### Configuring the autoscaler 



```bash
kubectl patch nodepool my-pool-zone-1 --type="merge" --patch='{"spec": {"autoscaling": {"scaleDownUnneededTimeSeconds": <a_value>, "scaleDownUnreadyTimeSeconds": <another_value>, "scaleDownUtilizationThreshold": "<and_another_one>"}}}'
```

For example, the result can be:

```bash
$ kubectl patch nodepool my-pool-zone-1 --type="merge" --patch='{"spec": {"autoscaling": {"scaleDownUnneededTimeSeconds": 900, "scaleDownUnreadyTimeSeconds": 1500, "scaleDownUtilizationThreshold": "0.7"}}}'

$ kubectl get nodepool my-pool-zone-1 -o json | jq .spec
{
  "antiAffinity": false,
  "autoscale": true,
  "autoscaling": {
    "scaleDownUnneededTimeSeconds": 900,
    "scaleDownUnreadyTimeSeconds": 1500,
    "scaleDownUtilizationThreshold": "0.7"
  },
  "desiredNodes": 3,
  "flavor": "b3-8",
  "maxNodes": 100,
  "minNodes": 1,
  "monthlyBilled": false
}
```