resource "ovh_cloud_project_kube" "my_cluster" {
  name          = "mks_free_gra11"
  region        = "GRA11"
}

resource "ovh_cloud_project_kube_nodepool" "node_pool_1" {
  service_name       = ovh_cloud_project_kube.my_cluster.service_name
  kube_id            = ovh_cloud_project_kube.my_cluster.id
  name               = "my-pool-zone-1" //Warning: "_" char is not allowed!
  flavor_name        = "b3-8"
  desired_nodes      = 3
}

output "kubeconfig_file" {
  value     = ovh_cloud_project_kube.my_cluster.kubeconfig
  sensitive = true
}
