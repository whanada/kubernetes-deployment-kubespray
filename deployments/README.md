# Optional cluster components

Run these scripts from a machine with Helm and a kubeconfig pointing to the target cluster. They install new releases and do not upgrade existing ones.

```bash
./deployments/cert-manager/install.sh
./deployments/traefik/install.sh
./deployments/longhorn/install.sh
```

- cert-manager 1.21.3 manages certificate issuance and renewal. Create an Issuer or ClusterIssuer for your certificate authority; installation alone does not issue certificates.
- Traefik Helm chart 42.4.1 installs an ingress controller with a LoadBalancer Service. MetalLB or another load balancer must provide its address. Configure DNS and use `ingressClassName: traefik` in Ingress resources.
- Longhorn 1.13.0 requires Kubernetes 1.34 or newer and node prerequisites such as iSCSI. Its data directory is `/data/longhorn`; verify storage and replication requirements before installation.

For existing installations, follow each project's documented upgrade path and back up cluster data first. Longhorn and cert-manager may require intermediate upgrades; do not jump directly from older releases.

## Let's Encrypt certificates

Install cert-manager and Traefik first. Create either a namespaced Issuer or a ClusterIssuer (the default is staging):

```bash
./deployments/cert-manager/create-issuer.sh admin@example.com my-namespace staging
./deployments/cert-manager/create-cluster-issuer.sh admin@example.com staging
```

Choose one issuer for an application. After validating the staging flow, repeat the relevant command with `production` and change the Ingress annotation to `letsencrypt-production`. Staging certificates are not browser-trusted.

For HTTP-01, the application's public DNS record must resolve to Traefik, and port 80 must be reachable from the internet. Port 443 must be reachable to serve HTTPS. HTTP-01 cannot issue wildcard certificates. A private MetalLB address needs public routing or NAT; otherwise use DNS-01.

Example Ingress using the ClusterIssuer (replace the hostname, service and port):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - app.example.com
      secretName: my-app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

For a namespaced Issuer, use `cert-manager.io/issuer` instead and create the Issuer in the application's namespace. cert-manager creates the challenge and TLS Secret; Traefik routes the HTTP challenge and serves the resulting certificate. Do not configure Traefik's built-in ACME resolver for the same certificates.

For an existing external CephFS filesystem, see [CephFS setup](cephfs/README.md).
