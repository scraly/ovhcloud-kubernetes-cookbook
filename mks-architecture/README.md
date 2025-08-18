# MKS architecture

## Communication inside a cluster

- Node to ControlPlane -> the public interface is used.
- ControlPlane to Node -> public interface is used (using the Konnectivity agent)
- Node to Node:
    - If your cluster is not attached to a private subnet: public interface are used
    - If your cluster is attached to a private subnet: inter-node communication is using private interfaces.
