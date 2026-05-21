# Notes for Claude

Context for working on this repo.

## What this is

A Helm chart for [clonarr](https://github.com/ProphetSe7en/clonarr), packaged
specifically for a personal Rancher-Desktop-on-macOS setup. Not a generic
upstream chart — opinionated defaults are intentional.

## Project conventions

- **Image pinning**: always by digest, not tag. `image.digest.amd64` and
  `image.digest.arm64` in `values.yaml`. Update both when bumping.
- **Persistence**: hostPath to `/Users/Shared/clonarr-config` so the Mac's
  Time Machine picks it up. Do not switch to a PVC by default.
- **Host networking quirks**: the *arr apps run as native macOS apps on the
  host. The pod reaches them via `host.docker.internal` (Rancher Desktop
  provides this DNS name automatically). Don't add a Service for them.
- **Tailscale ingress**: there's a `tailscaleIngress` preset that's mutually
  exclusive with the generic `ingress` block. The mutex is enforced in
  `templates/ingress.yaml` via `fail`. Don't break that contract.

## Release flow

- Versions ship via git tags of the form `v<chart>` or `v<chart>+app<app>`.
- `release.yaml` substitutes both into `Chart.yaml` before packaging, then
  pushes to `oci://ghcr.io/akarnani/charts/clonarr`.
- `validate.yaml` runs on PR/push: `helm lint`, multiple `helm template`
  cases, a negative test for the ingress mutex, then `kubeconform`.

When asked to cut a release:
1. Look up the latest clonarr release tag at
   https://github.com/ProphetSe7en/clonarr/releases.
2. Choose the next chart version (semver bump appropriate to the change).
3. Tag `v<chart>+app<appVersion>` and push.

## Things that have bitten us before

- `templates/NOTES.txt` used `index .Values.ingress.tls 0` which panics on an
  empty slice. Use `if .Values.ingress.tls` (empty slice is falsy) instead.
- The `kubeconform` docker action only mounts `$GITHUB_WORKSPACE` into the
  container — `/tmp/*` files are invisible. Install the binary directly in
  the workflow instead.
- Tailscale operator Ingress notes (verified against docs):
  - `secretName` in `tls` is optional and ignored by the operator
  - `tailscale.com/hostname` annotation is **Service-only**, not Ingress —
    Ingress hostname comes from `tls.hosts[0]`
  - `tailscale.com/http-redirect: "true"` works (operator >= v1.92.0)
  - `defaultBackend` is supported as an alternative to `rules`

## What to avoid

- Don't add features the user didn't ask for. This is a small personal chart;
  resist the urge to add ServiceMonitor, PodDisruptionBudget, HPA, etc.
- Don't switch persistence to a PVC unless asked — Time Machine backup is the
  whole reason for hostPath.
- Don't push tags without explicit confirmation — tag pushes trigger a
  publish to ghcr.io.
