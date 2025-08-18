# kyverno

In this Kyverno cookbook you can deploy & test useful Kyverno policies in MKS environment

Resource: https://help.ovhcloud.com/csm/fr-public-cloud-kubernetes-install-kyverno?id=kb_article_view&sysparm_article=KB0055165

## Installation

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

Result:

```bash
$ helm install kyverno kyverno/kyverno -n kyverno --create-namespace

Release "kyverno" has been upgraded. Happy Helming!
NAME: kyverno
LAST DEPLOYED: Mon Aug 18 14:56:01 2025
NAMESPACE: kyverno
STATUS: deployed
REVISION: 3
NOTES:
Chart version: 3.5.1
Kyverno version: v1.15.1

Thank you for installing kyverno! Your release is named kyverno.

The following components have been installed in your cluster:
- CRDs
- Admission controller
- Reports controller
- Cleanup controller
- Background controller


⚠️  WARNING: Setting the admission controller replica count below 2 means Kyverno is not running in high availability mode.
⚠️  WARNING: Generating ValidatingAdmissionPolicy requires a Kubernetes 1.27+ cluster with `ValidatingAdmissionPolicy` feature gate and `admissionregistration.k8s.io` API group enabled.
⚠️  WARNING: Generating reports from ValidatingAdmissionPolicies requires a Kubernetes 1.27+ cluster with `ValidatingAdmissionPolicy` feature gate and `admissionregistration.k8s.io` API group enabled.


⚠️  WARNING: PolicyExceptions are disabled by default. To enable them, set '--enablePolicyException' to true.

💡 Note: There is a trade-off when deciding which approach to take regarding Namespace exclusions. Please see the documentation at https://kyverno.io/docs/installation/#security-vs-operability to understand the risks.
```

Check the installed components:

```bash
$ kubectl get crd | grep kyverno
cleanuppolicies.kyverno.io                              2025-07-21T07:59:52Z
clustercleanuppolicies.kyverno.io                       2025-07-21T07:59:52Z
clusterephemeralreports.reports.kyverno.io              2025-07-21T07:59:52Z
clusterpolicies.kyverno.io                              2025-07-21T07:59:53Z
deletingpolicies.policies.kyverno.io                    2025-08-18T12:56:10Z
ephemeralreports.reports.kyverno.io                     2025-07-21T07:59:52Z
generatingpolicies.policies.kyverno.io                  2025-08-18T12:56:10Z
globalcontextentries.kyverno.io                         2025-07-21T07:59:52Z
imagevalidatingpolicies.policies.kyverno.io             2025-07-21T07:59:52Z
mutatingpolicies.policies.kyverno.io                    2025-08-18T12:56:10Z
policies.kyverno.io                                     2025-07-21T07:59:53Z
policyexceptions.kyverno.io                             2025-07-21T07:59:52Z
policyexceptions.policies.kyverno.io                    2025-07-21T07:59:52Z
updaterequests.kyverno.io                               2025-07-21T07:59:52Z
validatingpolicies.policies.kyverno.io                  2025-07-21T07:59:52Z

$ kubectl get po -n kyverno
NAME                                            READY   STATUS    RESTARTS   AGE
kyverno-admission-controller-68666f545d-2w4tl   1/1     Running   0          62s
kyverno-background-controller-5574bd864-hdzhb   1/1     Running   0          62s
kyverno-cleanup-controller-6fb8985659-tvjgq     1/1     Running   0          62s
kyverno-reports-controller-6989f55fff-2wzqt     1/1     Running   0          62s
```

## Deploy policies

### Managed Private Registry (MPR) only policy

You can ask Kyverno to deny the creation and the update of Pods if they don't use MPR (if DockerHub is forbidden for example).

Here the policy that you will deploy:

```yaml
apiVersion: policies.kyverno.io/v1alpha1
kind: ValidatingPolicy
metadata:
  name: private-reg-only
spec:
  matchConstraints:
    resourceRules:
      - apiGroups: [""]
        apiVersions: [v1]
        operations: [CREATE, UPDATE]
        resources: [pods]
  variables:
    - name: images
      expression: >-
        object.spec.containers.map(e, image(e.image))
        + object.spec.?initContainers.orValue([]).map(e, image(e.image))
        + object.spec.?ephemeralContainers.orValue([]).map(e, image(e.image))
  validations:
    - expression: >-
        object.metadata.namespace == "test-kyverno" &&
        variables.images.map(i, i.registry()).all(r, r.contains("container-registry.ovh.net"))
      message: >-
        images must be stored in OVHcloud Managed Private Registries
```

Create the namespace and create the secret for your upcoming Pods that alllows them to pull images from your MPR.

```bash
kubectl create ns test-kyverno

export PRIVATE_REGISTRY_URL=https://xxxx.c1.de1.container-registry.ovh.net
export PRIVATE_REGISTRY_USER=xxx
export PRIVATE_REGISTRY_PASSWORD=xxx
export PRIVATE_REGISTRY_URL_WITHOUT_SCHEME=xxxx.c1.de1.container-registry.ovh.net

kubectl -n test-kyverno create secret docker-registry ovhregistrycred --docker-server=$PRIVATE_REGISTRY_URL --docker-username=$PRIVATE_REGISTRY_USER --docker-password=$PRIVATE_REGISTRY_PASSWORD

kubectl get secret -n test-kyverno
```

Result:
```bash
$ kubectl get secret -n test-kyverno

NAME              TYPE                             DATA   AGE
ovhregistrycred   kubernetes.io/dockerconfigjson   1      4s
```

Deploy the policy:

```bash
kubectl apply -f mpr-policy.yaml
```

Check:
```bash
$ kubectl get vpol
NAME               AGE   READY
private-reg-only   7s    true
```

Test it with a good Pod:

```bash
kubectl apply -f my-pod.yaml -n test-kyverno
kubectl get po -n test-kyverno
```

The good pod is running:
```bash
$ kubectl get po -n test-kyverno

NAME     READY   STATUS    RESTARTS   AGE
my-pod   1/1     Running   0          13s
```

Test it with a wrong pod:

```bash
kubectl apply -f my-wrong-pod.yaml
```

Result:
```bash
$ kubectl apply -f my-wrong-pod.yaml

Error from server: error when creating "my-wrong-pod.yaml": admission webhook "vpol.validate.kyverno.svc-fail" denied the request: Policy private-reg-only failed: images must be stored in OVHcloud Managed Private Registries
```

You can't create a Pod that will pull an image from Docker Hub ;-).

### Clone the imagePullSecret from a source namespace to any newly create Namespace

Prerequisite: Kyverno 1.15.

```yaml
apiVersion: policies.kyverno.io/v1alpha1
kind: GeneratingPolicy
metadata:
  name: clone-image-pull-secret
spec:
  matchConstraints:
    resourceRules:
    - apiGroups:   [""]
      apiVersions: ["v1"]
      operations:  ["CREATE"]
      resources:   ["namespaces"]
  variables:
    - name: targetNs
      expression: "object.metadata.name"
    - name: sourceSecret
      expression: resource.Get("v1", "secrets", "test-kyverno", "ovhregistrycred") #test-kyverno = source namespace
  generate:
    - expression: generator.Apply(variables.targetNs, [variables.sourceSecret])
```

In this policy, the creation of a new Namespace (the trigger) causes Kyverno to fetch the `ovhregistrycred` secret from the `test-kyverno` namespace (the source) and create a copy of it in the new namespace (the downstream resource).

### Rancher webhooks should not manages the secrets in the kube-system namespace

If you have Rancher installed in your cluster, sometimes you can have "USER_WEBHOOK_PREVENTING_OPERATIONS_ERROR" error in your MKS cluster.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: mutate-rancher-secrets-webhookconfiguration
  annotations:
    policies.kyverno.io/title: Filter Rancher secrets WebhookConfiguration
    policies.kyverno.io/description: >-
      Filter Rancher WebhookConfiguration to match secrets not in the `kube-system` namespace
spec:
  mutateExistingOnPolicyUpdate: true
  rules:
    - name: mutate-rancher-secrets-mutatingwebhookconfiguration
      match:
        any:
        - resources:
            kinds:
            - MutatingWebhookConfiguration
            names:
            - rancher.cattle.io
      mutate:
        targets:
        - apiVersion: admissionregistration.k8s.io/v1
          kind: MutatingWebhookConfiguration
          name: rancher.cattle.io
        patchStrategicMerge:
          webhooks:
            - name: rancher.cattle.io.secrets
              namespaceSelector:
                matchExpressions:
                  - key: kubernetes.io/metadata.name
                    operator: NotIn
                    values:
                      - kube-system
    - name: mutate-rancher-secrets-validatingwebhookconfigurations
      match:
        any:
        - resources:
            kinds:
            - ValidatingWebhookConfiguration
            names:
            - rancher.cattle.io
      mutate:
        targets:
        - apiVersion: admissionregistration.k8s.io/v1
          kind: ValidatingWebhookConfiguration
          name: rancher.cattle.io
        patchStrategicMerge:
          webhooks:
            - name: rancher.cattle.io.secrets
              namespaceSelector:
                matchExpressions:
                  - key: kubernetes.io/metadata.name
                    operator: NotIn
                    values:
                      - kube-system
```

⚠️ When Rancher restarts, it recreates the webhookconfiguration, so sometimes there is some latency from Kyverno to re-apply it