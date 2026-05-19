### What's changed in v0.1.1

* fix: make init Job idempotent so re-runs do not wipe settings (by @patrickleet)

  The init Job ran on every Helm upgrade (chart values change → Job spec
  change → Helm replaces the Job). With `--install --yes` (no
  `--idempotent`), each rerun reset the settings table — including
  `security.oidc.enabled` set by an operator and `app.root_url` adapted
  for a public host. Switch to `--install --idempotent --yes` so reruns
  are non-destructive. The pre-check skip flag remains as a fast-path.


See full diff: [v0.1.0...v0.1.1](https://github.com/hops-ops/listmonk-chart/compare/v0.1.0...v0.1.1)
