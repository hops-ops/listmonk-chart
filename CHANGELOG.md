### What's changed in v0.1.0

* feat: initial fork of redzumi/listmonk-chart (by @patrickleet)

  Forked from redzumi/listmonk-chart 2.0.1 (Listmonk v6.0.0). Two additions:

  - extraEnvFrom + extraEnv on the Listmonk Deployment so SMTP and OIDC
    credentials can be projected via env from ExternalSecret-managed Secrets.

  - Native [security.oidc] config in config.toml when oidc.enabled=true,
    plus matching LISTMONK_security__oidc__* env vars so Listmonk's koanf
    loader picks the values up on startup. Listmonk v4.1+ ships OIDC SSO
    natively; this chart now exposes that surface declaratively.

  Workflows mirror hops-ops/openpanel-chart (vnext-driven release, helm
  quality CI, on-version-tagged publishes the chart to gh-pages).


