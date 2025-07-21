# External Secret Operator (ESO)

## Installation

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

Install from the Helm chart:

```bash
helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace
```

Result:

```bash
$ helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace

NAME: external-secrets
LAST DEPLOYED: Fri Jul 18 14:26:30 2025
NAMESPACE: external-secrets
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
external-secrets has been deployed successfully in namespace external-secrets!

In order to begin using ExternalSecrets, you will need to set up a SecretStore
or ClusterSecretStore resource (for example, by creating a 'vault' SecretStore).

More information on the different types of SecretStores and how to configure them
can be found in our Github: https://github.com/external-secrets/external-secrets
```

Check created pods:

```bash
$ kubectl get po -n external-secrets
NAME                                                READY   STATUS    RESTARTS   AGE
external-secrets-6566c4cfdd-szv5r                   1/1     Running   0          2d20h
external-secrets-cert-controller-86794c66b7-msd8p   1/1     Running   0          2d20h
external-secrets-webhook-574788fc77-2t4jd           1/1     Running   0          2d20h
```

## Usage

### Synchronize a secret accross several namespaces (kubernetes.io/dockerconfigjson)

This use case is useful when you deployed a secret in one namespace that allows Pods to pull image coming from your OVHcloud Private Registry, and you want to deploy, automatically, this secret also in several other namespace.

For this need we will you the [External Secret Kubernetes provider](https://external-secrets.io/latest/provider/kubernetes/).

Here the ClusterSecretStore that we will deploy:

```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: mpr-secret-store
spec:
  provider:
    kubernetes:
      remoteNamespace: test-kyverno #source namespace where the secret is
      server:
        caProvider:
          type: ConfigMap
          name: kube-root-ca.crt # Certificat du cluster. Chaque namespace possède un ConfigMap kube-root-ca.crt qui contient le certificat du serveur interne
          key: ca.crt
          namespace: test-kyverno
      auth:
        serviceAccount:
          name: external-secrets # Référence un service account pour récupérer le secret. Par simplicité nous utilisons ici un service account automatiquement créé lors d’installation de ESO, qui a tous les droits nécessaires 
          namespace: external-secrets
```

Deploy the ClusterSecretStore:

```bash
kubectl apply -f mpr-secret-store.yaml
```

Check:

```bash
$ kubectl get clustersecretstore
NAME               AGE   STATUS   CAPABILITIES   READY
mpr-secret-store   12s   Valid    ReadWrite      True
```

Here the ExternalSecret, that will copy the secret from `test-kyverno` namespace to `hello-app` namespace, that we will deploy:

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: pull-my-secret
  namespace: hello-app
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: mpr-secret-store
    kind: ClusterSecretStore
  target:
    name: ovhregistrycred # name of the k8s Secret to be created
    template:
      type: kubernetes.io/dockerconfigjson
  data:
  - secretKey: .dockerconfigjson
    remoteRef:
      key: ovhregistrycred
```

Deploy the targetted namespace:

```bash
kubectl create ns hello-app
```

Deploy the ExternalSecret:

```bash
kubectl apply -f mpr-external-secret.yaml
```

Display the created ExternalSecret and the created secret:

```bash
$ kubectl get externalsecret pull-my-secret -n hello-app
NAME             STORETYPE            STORE              REFRESH INTERVAL   STATUS         READY
pull-my-secret   ClusterSecretStore   mpr-secret-store   1h                 SecretSynced   True

$ kubectl get secret -A
NAMESPACE          NAME                                                      TYPE                             DATA   AGE
...
hello-app          ovhregistrycred                                           kubernetes.io/dockerconfigjson   1      86s
...
test-kyverno       ovhregistrycred                                           kubernetes.io/dockerconfigjson   1      114m

$ kubectl get secret ovhregistrycred -n hello-app -o yaml
apiVersion: v1
data:
  .dockerconfigjson: eyIuZG9ja2VyY29uZmlnanNvbiI6IntcImF1dGhzXCI6e1wiaHR0cHM6Ly83OTM1Mmg4di5jMS5kZTEuY29udGFpbmVyLXJlZ2lzdHJ5Lm92aC5uZXRcIjp7XCJ1c2VybmFtZVwiOlwiYXVyZWxpZVwiLFwicGFzc3dvcmRcIjpcIjhUS1M0Zm5jXCIsXCJhdXRoXCI6XCJZWFZ5Wld4cFpUbzRWRXRUTkdadVl3PT1cIn19fSJ9
kind: Secret
metadata:
  annotations:
    reconcile.external-secrets.io/data-hash: bd8e2a876feda12120ff96459c60923477bf013cf95509e46e66d58b
  creationTimestamp: "2025-07-21T09:55:22Z"
  labels:
    reconcile.external-secrets.io/created-by: 7870d14eb787583a2c5ebfa41ec5ad11295f7b525eac49b33ef9c2bf
    reconcile.external-secrets.io/managed: "true"
  name: ovhregistrycred
  namespace: hello-app
  ownerReferences:
  - apiVersion: external-secrets.io/v1
    blockOwnerDeletion: true
    controller: true
    kind: ExternalSecret
    name: pull-my-secret
    uid: ce822cdb-e071-4e0f-a844-2754c5a2e4ee
  resourceVersion: "1466124"
  uid: 6312cd9b-5d09-4184-ad3f-2368027a0909
type: kubernetes.io/dockerconfigjson
```