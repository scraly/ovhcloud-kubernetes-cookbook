## Create a MKS Free cluster with Terraform

### General information
 - 🔗 [Using Terraform with OVHcloud](https://help.ovhcloud.com/csm/fr-terraform-at-ovhcloud?id=kb_article_view&sysparm_article=KB0054776)
 - 🔗 [Creating a cluster through Terraform](https://help.ovhcloud.com/csm/fr-public-cloud-kubernetes-create-cluster-with-terraform?id=kb_article_view&sysparm_article=KB0054966)
 - 🔗 [How to use Terraform](https://help.ovhcloud.com/csm/en-gb-public-cloud-compute-terraform?id=kb_article_view&sysparm_article=KB0050787)
 - 🔗 [ovh_cloud_project_kube](https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_kube)
 - 🔗 [OVH token generation page](https://www.ovh.com/auth/api/createToken?GET=/*&POST=/*&PUT=/*&DELETE=/*)

### Set up
  - Install the [Terraform CLI](https://www.terraform.io/downloads.html)
  - Get the credentials from the OVHCloud Public Cloud project:
    - `application_key`
    - `application_secret`
    - `consumer_key`
  - Get the `service_name` (Public Cloud project ID)
  - Install the kubectl CLI

### Demo
  - set the environment variables `OVH_APPLICATION_KEY`, `OVH_APPLICATION_SECRET`, `OVH_CONSUMER_KEY` and `OVH_CLOUD_PROJECT_SERVICE`

```bash
# OVHcloud provider needed keys
export OVH_ENDPOINT="ovh-eu"
export OVH_APPLICATION_KEY="xxx"
export OVH_APPLICATION_SECRET="xxx"
export OVH_CONSUMER_KEY="xxx"
export OVH_CLOUD_PROJECT_SERVICE="xxx"
```
  - use the [kube.tf](my-ovh_kube_cluster.tf) file to define the resources to create and to display the kubeconfig file at the end of Terraform execution
  - run the `terraform init` command
  - run the `terraform apply` command (~ 5-7 mins)

```bash
...
ovh_cloud_project_kube.my_cluster: Still creating... [2m50s elapsed]
ovh_cloud_project_kube.my_cluster: Creation complete after 2m51s [id=1ebec32b-636c-43e5-9ffd-636d51e9a75f]
...
ovh_cloud_project_kube_nodepool.node_pool_1: Still creating... [2m20s elapsed]
ovh_cloud_project_kube_nodepool.node_pool_1: Creation complete after 2m23s [id=c980ebf6-78be-4a51-a187-a858cd3060c5]
```

  - get the `kubeconfig` value:

`terraform output -raw kubeconfig > mks_free_gra11.yml`

  - save the path of kubeconfig in an environment variable (for later ^^)

```bash
export KUBE_CLUSTER=$(pwd)/mks_free_gra11.yml
```

  - test the connexion to the Kubernetes:
  
`kubectl --kubeconfig=$KUBE_CLUSTER cluster-info`

  - list the node pool configuration:

`kubectl --kubeconfig=$KUBE_CLUSTER get np`

  - list the nodes:

`kubectl --kubeconfig=$KUBE_CLUSTER get no`

### Destroy

  - destroy the cluster: `terraform destroy`
