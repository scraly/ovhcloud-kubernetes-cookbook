#!/bin/bash

########################
# include the magic
########################
. bin/demo-magic.sh

# hide the evidence
clear

pe "kubectl create ns hello-app"

p 'Create the Secret'
pe "kubectl -n hello-app create secret docker-registry ovhregistrycred --docker-server=$PRIVATE_REGISTRY_URL --docker-username=$PRIVATE_REGISTRY_USER --docker-password=$PRIVATE_REGISTRY_PASSWORD"

p 'Check the secret has been correctly deployed in your Kubernetes cluster'
pe "kubectl get secret ovhregistrycred -o jsonpath='{.data.\.dockerconfigjson}' -n hello-app"

p "Edit the app's image with the created registry and project"

pe 'cd overlays/prod'

pe 'kustomize edit set image hello-ovh="${PRIVATE_REGISTRY_URL_WITHOUT_SCHEME}/${PRIVATE_REGISTRY_PROJECT}/hello-ovh:1.0.0-linuxamd64"'

p 'Deploy an app (linked to the created private registry)'

pe 'kustomize build . | kubectl apply -f - -n hello-app'

p 'Check the app is running correctly (and image have been pulled successfully)''

pe 'kubectl get po -o wide -l app=hello-ovh -n hello-app'
pe 'kubectl describe po -l app=hello-ovh -n hello-app'

p 'Display the result'
pe "export SERVICE_URL=$(kubectl get svc hello-ovh -n hello-app -o jsonpath='{.status.loadBalancer.ingress[].ip}')"

pe 'curl $SERVICE_URL'