# Cluster infrastructure

The diagram describes the configured infrastructure and optional components. It is not a record of a successful deployment. Optional components are installed separately. Zabbix and its database stack are not implemented in this repository.

```mermaid
flowchart TB
    admin["Operator workstation<br/>Ansible + Python venv"]
    user["Users / applications"]
    le["Let's Encrypt<br/>optional HTTP-01"]
    ceph["Existing external Ceph cluster<br/>CephFS + MDS + data pool"]

    subgraph cluster["Kubernetes cluster — Kubespray"]
        direction TB
        vip["kube-vip<br/>Kubernetes API VIP"]
        subgraph cp["Control plane — 3 nodes in inventory"]
            api["Kubernetes API server"]
            controllers["Scheduler + controller manager"]
            etcd[("etcd — 3 members")]
        end
        subgraph services["Cluster services"]
            cilium["Cilium CNI"]
            dns["CoreDNS + NodeLocal DNS"]
            proxy["kube-proxy"]
            metrics["Metrics Server"]
            metallb["MetalLB<br/>LoadBalancer IP pool"]
        end
        subgraph workers["Worker nodes"]
            runtime["containerd + kubelet"]
            apps["Application workloads"]
        end
        subgraph optional["Optional components — installed separately"]
            traefik["Traefik ingress controller"]
            cert["cert-manager"]
            issuer["Issuer or ClusterIssuer"]
            tls["TLS Secret"]
            longhorn["Longhorn + StorageClass"]
            csi["Ceph-CSI Operator + CephFS driver"]
            cephsc["CephFS StorageClass + Secret"]
        end
    end

    admin -->|"SSH / Ansible"| cp
    admin -->|"SSH / Ansible"| workers
    admin -->|"kubectl / Helm"| api
    vip --> api
    api --> etcd
    controllers --> api
    runtime --> api
    cilium --- runtime
    dns --- apps
    proxy --- apps
    metrics -->|"node metrics"| runtime
    metallb -->|"assigns LoadBalancer IP"| traefik
    user -->|"HTTP / HTTPS"| traefik
    traefik --> apps
    cert --> issuer
    issuer <-->|"ACME HTTP-01"| le
    le -->|"challenge via HTTP"| traefik
    cert -->|"creates / renews"| tls
    traefik -->|"uses"| tls
    apps -->|"PVC"| longhorn
    apps -->|"PVC"| cephsc
    cephsc --> csi
    csi -->|"network + CephX"| ceph
```
