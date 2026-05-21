# clonarr-helm

A Helm chart for [clonarr](https://github.com/ProphetSe7en/clonarr) — a visual
TRaSH Guides sync tool for Radarr and Sonarr.

Built for a personal setup: Rancher Desktop on macOS, the *arr apps running as
native macOS apps on the host network, and Tailscale for remote access.

## Install

```bash
helm install clonarr oci://ghcr.io/akarnani/charts/clonarr \
  --version 0.1.1 \
  -f values.yaml
```

Pin by chart digest for full reproducibility:

```bash
helm install clonarr oci://ghcr.io/akarnani/charts/clonarr \
  --version sha256:<digest> \
  -f values.yaml
```

## Key configuration

### Image digest pinning

Images are pinned by a **multi-arch manifest list digest**, so the same digest
works on amd64 and arm64 nodes — the registry serves the right per-arch image
automatically at pull time. To bump:

```bash
docker buildx imagetools inspect ghcr.io/prophetse7en/clonarr:<tag>
# copy the top-level "Digest:" line into image.digest in values.yaml
```

To use a floating tag instead, set `image.digest: ""` and `image.tag: "<tag>"`.

### Reaching Radarr/Sonarr on the macOS host

If the *arr apps run as native macOS apps (not in containers), use
`host.docker.internal` from inside the cluster. That hostname resolves to the
Rancher Desktop VM's host (the Mac) automatically. Configure clonarr's Radarr
/ Sonarr URLs as e.g. `http://host.docker.internal:7878`.

### Config persistence

Config is mounted via `hostPath` to `/Users/Shared/clonarr-config` on the Mac
so Time Machine can back it up. Override with `persistence.hostPath`.

### Tailscale ingress (preset)

Easiest path if you use the Tailscale Kubernetes operator:

```yaml
tailscaleIngress:
  enabled: true
  hostname: clonarr       # becomes clonarr.<tailnet>.ts.net
  httpRedirect: true      # requires operator >= v1.92.0
```

Reachable at `https://clonarr.<tailnet>.ts.net` with automatic MagicDNS cert
and HTTP→HTTPS redirect. Mutually exclusive with the generic `ingress` block.

### Generic ingress

For nginx, traefik, etc:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: clonarr.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts: [clonarr.example.com]
      secretName: clonarr-tls
```

## Releasing

Versions are published by pushing a git tag. Two formats:

| Tag | Chart version | App version |
|---|---|---|
| `v0.2.0` | `0.2.0` | from committed `Chart.yaml` |
| `v0.2.0+app2.5.9` | `0.2.0` | `2.5.9` |

The `release.yaml` workflow substitutes these into `Chart.yaml`, packages,
and pushes to `ghcr.io/akarnani/charts/clonarr`.

PRs are validated by `validate.yaml`: `helm lint`, three `helm template` cases
(defaults, generic ingress, tailscale ingress), a negative test for the
mutex-fail between the two ingress modes, and `kubeconform` against the
rendered manifests.

## License

[MIT](LICENSE)
