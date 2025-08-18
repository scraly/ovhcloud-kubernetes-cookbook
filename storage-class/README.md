# StorageClass

Several StorageClasses are installed by default in MKS clusters.
But you can deploy other ones:

## high-speed-gen2-luks StorageClass

Prerequisite: create the encryption key?

For LUKS encrypted volumes.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-cinder-high-speed-gen2-luks
allowVolumeExpansion: true
parameters:
  availability: nova
  fsType: ext4
  type: high-speed-gen2-luks
provisioner: cinder.csi.openstack.org
reclaimPolicy: Delete
volumeBindingMode: Immediate 
```

N.B: LUKS (Linux Unified Key Setup) is a standard on-disk format for hard disk encryption.

## Controlling the PV creation on a specific AZ on MKS 3AZ

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-cinder-high-speed-gen2-eu-west-par-b
allowVolumeExpansion: true
parameters:
  availability: nova
  fsType: ext4
  type: high-speed-gen2-luks
provisioner: cinder.csi.openstack.org
reclaimPolicy: Delete
volumeBindingMode: Immediate 
allowedTopologies:
- matchLabelExpressions:
  - key: topology.cinder.csi.openstack.org/zone
    values:
    - eu-west-par-b
```

Aivailable zones are `eu-west-par-a`, `eu-west-par-b`, `eu-west-par-c`.
