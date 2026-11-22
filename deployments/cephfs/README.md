# External CephFS StorageClass

This optional setup connects Kubernetes to an **existing Ceph cluster and CephFS filesystem**. It does not create Ceph pools, filesystems or credentials. A pool alone is not a CephFS filesystem: create or select a CephFS filesystem and, if using a dedicated data pool, attach that pool to it first. Ensure the filesystem has active MDS servers and the `csi` subvolume group. Use a CephX user with the capabilities required for that filesystem and subvolume group.

Prerequisites: cluster-admin access via `kubectl`, working network access from Kubernetes nodes to Ceph monitors, OSDs and MDS, and compatible Ceph and node kernel versions. If Rook already manages Ceph-CSI, do not install a second operator; follow the Rook external-cluster documentation instead.

1. Install the Ceph-CSI Operator v1.1.0 once:

   ```bash
   ./deployments/cephfs/install-operator.sh
   ```

2. Create the CephX Secret. Store the raw base64 key in a protected local file outside this repository. The user ID omits the `client.` prefix:

   ```bash
   ./deployments/cephfs/create-secret.sh csi-cephfs /secure/path/to/ceph-key
   ```

   By default the script creates `cephfs-csi-secret` in `ceph-csi-operator-system`, matching the example StorageClass. Optional third and fourth arguments set the namespace and Secret name. If changed, update every Secret reference in the StorageClass. The script creates a new Secret and fails if it already exists; it does not rotate an existing credential.

3. Copy `cephfs.example.yaml` to a local file outside the repository. Edit the Ceph monitor endpoints, `fsName`, and optional data `pool`. The pool must already be attached to the filesystem. Do not change `clusterID` unless it matches the `ClientProfile` name. Review and apply the file:

   ```bash
   kubectl apply -f /path/to/cephfs.yaml
   kubectl get storageclass cephfs
   kubectl -n ceph-csi-operator-system get pods
   ```

4. Request a volume using `storageClassName: cephfs` and `accessModes: [ReadWriteMany]`. Test provisioning, mounting from multiple nodes, expansion and recovery before production.

The class is not the default. Its `Retain` reclaim policy preserves the backing volume after PVC deletion; administrators must clean up retained data explicitly. The scripts do not configure snapshots or backups.

References: [CephFS with Ceph-CSI](https://docs.ceph.com/en/latest/csi/cephfs/), [operator installation](https://github.com/ceph/ceph-csi-operator/blob/v1.1.0/docs/kubernetes-installation.md), and [required CephX capabilities](https://github.com/ceph/ceph-csi/blob/v3.18.1/docs/capabilities.md).
