# CNI

Currently, the 1-AZ setup uses Canal as the CNI, while the 3-AZ (standard) deployment uses Cilium.

After the Standard (3-AZ) release in GA: we plan to roll out Cilium on all regions/plan.

Existing cluster will remain on Canal but users will be able to choose their CNI for new clusters.