# cert-manager

## Installation

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

Install the latest version of cert-manager:

```bash
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --values values.yaml
```

/!\ `values.yaml` file is necessary to "fix" blocking [ingress-nginx 1.18+ changes](https://cert-manager.io/docs/releases/release-notes/release-notes-1.18/#acme-http01-challenge-paths-now-use-pathtype-exact-in-ingress-routes).

Result:

```bash
$ helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --values values.yaml
NAME: cert-manager
LAST DEPLOYED: Mon Jul 21 15:58:28 2025
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
⚠️  WARNING: New default private key rotation policy for Certificate resources.
The default private key rotation policy for Certificate resources was
changed to `Always` in cert-manager >= v1.18.0.
Learn more in the [1.18 release notes](https://cert-manager.io/docs/releases/release-notes/release-notes-1.18).

cert-manager v1.18.2 has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.io/docs/configuration/

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://cert-manager.io/docs/usage/ingress/
```

Check cert-manager have been deployed correctly:

```bash
$ kubectl get pods -n cert-manager
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-587c49b686-qbvk8              1/1     Running   0          63s
cert-manager-cainjector-55cd9f77b5-rnnql   1/1     Running   0          63s
cert-manager-webhook-7987476d56-7fx7b      1/1     Running   0          63s
```

Deploy letsencrypt-prod issuer:

```bash
kubectl apply -f issuer.yaml
kubectl get clusterissuer
```

Result:

```bash
$ kubectl apply -f issuer.yaml

clusterissuer.cert-manager.io/letsencrypt-prod created

$ kubectl get clusterissuer
NAME               READY   AGE
letsencrypt-prod   True    2m9s
```
