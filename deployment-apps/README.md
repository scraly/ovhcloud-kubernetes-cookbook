# Apps deployment

## Deploy pods accross several availability zones

Follow [Deployment apps in 3AZ README file](./deployment-apps-3az/README.md).

## Deploy pods only in a desired availability zone

Create a nginx-one-az.yaml file with the following content:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-one-az
  labels:
    app: nginx-one-az
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-one-az
  template:
    metadata:
      labels:
        app: nginx-one-az
    spec:
      nodeSelector:
        topology.kubernetes.io/zone: eu-west-par-a
      containers:
      - name: nginx
        image: nginx:1.28.0
        ports:
        - containerPort: 80
```

Deploy the manifest file in your cluster:

```bash
$ kubectl apply -f nginx-one-az.yaml -n hello-app
deployment.apps/nginx-one-az created
```

As you can see, our three pods are running in the PAR region only in the zone-a nodes:

```bash
$ kubectl get po -o wide -l app=nginx-one-az -n hello-app
NAME                            READY   STATUS    RESTARTS   AGE    IP             NODE                         NOMINATED NODE   READINESS GATES
nginx-one-az-6b5f9bdccc-8vv9l   1/1     Running   0          98s    10.240.7.13    my-pool-zone-a-b9ztj-brgpq   <none>           <none>
nginx-one-az-6b5f9bdccc-ck99s   1/1     Running   0          100s   10.240.5.216   my-pool-zone-a-b9ztj-mss8j   <none>           <none>
nginx-one-az-6b5f9bdccc-tlg4d   1/1     Running   0          96s    10.240.8.221   my-pool-zone-a-b9ztj-gt5vd   <none>           <none>
```