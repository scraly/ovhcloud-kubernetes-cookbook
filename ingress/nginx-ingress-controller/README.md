# Nginx Ingress Controller

## Instalation

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm -n ingress-nginx install ingress-nginx ingress-nginx/ingress-nginx --create-namespace
```

Result:
```bash
$ helm -n ingress-nginx install ingress-nginx ingress-nginx/ingress-nginx --create-namespace
NAME: ingress-nginx
LAST DEPLOYED: Mon Jul 21 13:41:36 2025
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the load balancer IP to be available.
You can watch the status by running 'kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

As the LoadBalancer creation is asynchronous, and the provisioning of the load balancer can take several minutes, you will surely get a <pending> EXTERNAL-IP.

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

If you try again in a few minutes you should get an EXTERNAL-IP.

Result:

```bash
$ kubectl get svc -n ingress-nginx ingress-nginx-controller
NAME                       TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                      AGE
ingress-nginx-controller   LoadBalancer   10.3.162.74   57.130.28.169   80:32395/TCP,443:32451/TCP   2m34s
```

You can then access your nginx-ingress at http://[YOUR_LOAD_BALANCER_IP] via HTTP or https://[YOUR_LOAD_BALANCER_IP] via HTTPS.

Enter the following command to retrieve it:

```bash
export INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[].ip}')
echo $INGRESS_IP
```

## Usage

### Deploy an ingress

### TODO: Secure it through cert-manager

### TODO: Have access to real client IP in applications

By default, when deploying services through a LoadBalancer, the LB act as a proxy, so the remote address of an application will be the IP of the LB, not the source UP of the request.

The solution is to preserve the source IP.
 
real-ip-values.yaml:
```yaml
controller:
  service:
    externalTrafficPolicy: "Local"
    annotations:
      # For Managed Kubernetes Service version < 1.31
      #service.beta.kubernetes.io/ovh-loadbalancer-proxy-protocol: "v2"
      # For Managed Kubernetes Service version >= 1.31
      loadbalancer.openstack.org/proxy-protocol : "v2"
  config:
    use-proxy-protocol: "true"
    real-ip-header: "proxy_protocol"
    # For Public network
    # kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.metadata.annotations.lb\.k8s\.ovh\.net/egress-ips}"
    #proxy-real-ip-cidr: "aaa.aaa.aaa.aaa/32,bbb.bbb.bbb.bbb/32,ccc.ccc.ccc.ccc/32,ddd.ddd.ddd.ddd/32"
    # For private network
    proxy-real-ip-cidr: "xx.yy.zz.aa/nn" #your subnet range
```

Patch your Nginx Ingress Controller:

```bash
helm upgrade ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx -f real-ip-values.yaml
````

We can now deploy a simple echo service to verify that everything is working. The service will use the mendhak/http-https-echo image, a very useful HTTPS echo Docker container for web debugging.

First, copy the next manifest to a echo.yaml file:

apiVersion: v1
kind: Namespace
metadata:
  name: echo

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-deployment
  namespace: echo
  labels:
    app: echo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: mendhak/http-https-echo
        ports:
        - containerPort: 80
        - containerPort: 443

---

apiVersion: v1
kind: Service
metadata:  
  name: echo-service
  namespace: echo
spec:
  selector:
    app: echo
  ports:  
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-ingress
  namespace: echo
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - http:
      paths:
        - path: "/"
          pathType: Prefix
          backend:
            service:
              name: echo-service
              port:
                number: 80

And deploy it on your cluster:

kubectl apply -f echo.yaml

$ kubectl apply -f echo.yaml
namespace/echo created
deployment.apps/echo-deployment created
service/echo-service created
ingress.extensions/echo-ingress created

Now you can test it using the LoadBalancer URL:

curl  xxx.xxx.xxx.xxx

And you should get the HTTP parameters of your request, including the right source IP in the x-real-ip header:

{
  "path": "/",
  "headers": {
    "host": "xxx.xxx.xxx.xxx",
    "x-request-id": "2126b343bc837ecbd07eca904c33daa3",
    "x-real-ip": "XXX.XXX.XXX.XXX",
    "x-forwarded-for": "XXX.XXX.XXX.XXX",
    "x-forwarded-host": "xxx.xxx.xxx.xxx",
    "x-forwarded-port": "80",
    "x-forwarded-proto": "http",
    "x-original-uri": "/",
    "x-scheme": "http",
    "user-agent": "curl/7.58.0",
    "accept": "*/*"
  },
  "method": "GET",
  "body": "",
  "fresh": false,
  "hostname": "xxx.xxx.xxx.xxx",
  "ip": "::ffff:10.2.1.2",
  "ips": [],
  "protocol": "http",
  "query": {},
  "subdomains": [
    "k8s",
    "gra",
    "c1",
    "lb",
    "6d6rslnrn8"
  ],
  "xhr": false,
  "os": {
    "hostname": "echo-deployment-6b6fdc96cf-hwqw6"
  }
}