# StorageClass

Several StorageClasses are installed by default in MKS clusters.
But you can deploy other ones:

## high-speed-gen2-luks (Encrypted block volume) StorageClass

Since 17th of June 2025, it's possible to create encrypted block volume with OMK (OVHcloud managed key)  in RBX-A, SBG, Paris & BHS [regions](https://github.com/ovh/public-cloud-roadmap/issues/307).

Encrypted volume types are named with "-luks" at the end, so you will find 3 new volume types: Classic-luks, High-speed-luks, High-speed-gen2-luks.

Here a StorageClass in order to use High-speed-gen2-luks encrypted volumes:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-cinder-high-speed-gen2-luks
allowVolumeExpansion: true
parameters:
  fsType: ext4
  type: high-speed-gen2-luks
provisioner: cinder.csi.openstack.org
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

N.B: LUKS (Linux Unified Key Setup) is a standard on-disk format for hard disk encryption.

⚠️ A new OpenStack Barbican secret will be created for each volume. Don't edit or delete it!

## Controlling the PV creation on a specific AZ on MKS 3AZ

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-cinder-high-speed-gen2-eu-west-par-b
allowVolumeExpansion: true
parameters:
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
