# listmonk-chart

A Helm chart for deploying [Listmonk](https://listmonk.app) — a self-hosted
newsletter and mailing-list manager — on Kubernetes.

Fork of [redzumi/listmonk-chart](https://github.com/redzumi/listmonk-chart)
with two additions:

- **`extraEnvFrom` / `extraEnv`** on the Listmonk Deployment — project SMTP +
  OIDC credentials as env from `ExternalSecret`-managed Secrets without
  forking the chart again.
- **Native OIDC config in `config.toml`** — when `oidc.enabled: true`, the
  chart renders a `[security.oidc]` block and emits matching
  `LISTMONK_security__oidc__*` env vars so Listmonk's koanf loader picks the
  values up at startup.

App: Listmonk v6.0.0.

## Installation

```bash
helm repo add hops-ops-listmonk https://hops-ops.github.io/listmonk-chart
helm repo update
helm install marketing hops-ops-listmonk/listmonk \
  --namespace marketing --create-namespace
```

## OIDC

Listmonk v4.1+ supports OIDC natively. The Listmonk OAuth redirect URI is
`https://<host>/auth/oidc` — register that with your IdP.

`client_id` and `client_secret` are **not** written to `config.toml`. They
must be projected as env via `extraEnvFrom`, sourced from a Kubernetes
Secret carrying these exact keys:

```yaml
data:
  LISTMONK_security__oidc__client_id:     base64(...)
  LISTMONK_security__oidc__client_secret: base64(...)
```

Example values:

```yaml
oidc:
  enabled: true
  providerUrl: https://auth.example.com
  providerName: Zitadel

extraEnvFrom:
  - secretRef:
      name: listmonk-oidc-client
```

## SMTP

Listmonk reads SMTP settings from the database (managed in the admin UI).
The chart's `smtp.existingSecret` slot is wired through `extraEnvFrom` in
this fork so SMTP values are also overridable via env on Pod restart. The
Secret must use the Listmonk env-var naming:

```yaml
data:
  LISTMONK_smtp__0__host:     ...
  LISTMONK_smtp__0__port:     ...
  LISTMONK_smtp__0__username: ...
  LISTMONK_smtp__0__password: ...
```

```yaml
extraEnvFrom:
  - secretRef:
      name: listmonk-smtp
```

## Workflow

Releases are driven by [unbounded-tech/workflow-vnext-tag](https://github.com/unbounded-tech/workflow-vnext-tag).
Conventional Commit prefixes on PR titles/commits to `main` produce a
semver bump; the resulting tag triggers `on-version-tagged.yaml` which
packages the chart and publishes to `gh-pages` (the Helm repo index).

## License

Apache-2.0
