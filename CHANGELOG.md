### What's changed in v0.2.0

* feat(adminAuth): post-install hook mints type=api user + Secret (#2) (by @patrickleet)

  * feat(adminAuth): post-install hook mints type=api user + Secret

  Adds an opt-in `adminAuth.createApiUser` feature: when enabled, a
  post-install,post-upgrade Helm hook idempotently mints a `type=api`
  Listmonk User in the database and writes its credentials to a
  Kubernetes Secret in the install namespace. Pairs with
  `terraform-provider-listmonk` (and the upjet-generated Crossplane
  `provider-listmonk`) which authenticate via HTTP Basic-Auth against
  that Secret.

  Stock-chart-safe: gated on `adminAuth.createApiUser`, default `false`.
  Non-platform users see no behavior change.

  Mechanism:
  - ServiceAccount + Role (resourceNames-scoped to the single Secret +
    single Deployment) + RoleBinding
  - 4-step Job: prepare-token (read Secret OR generate via two UUIDs
    concat → 244 bits entropy) → write-db (pg_isready loop, users-table
    loop, idempotent INSERT … ON CONFLICT (username) DO UPDATE) →
    write-secret (kubectl apply --server-side with field-manager
    `listmonk-chart` so co-managing controllers don't oscillate) →
    restart-listmonk (rollout restart the Listmonk Deployment so
    apiUsers cache reloads with the new row; gracefully no-ops if the
    Deployment is absent)
  - post-install,post-upgrade timing: pre-install was the natural fit
    but blocked on ordering with the chart-managed Postgres StatefulSet
    and config.toml ConfigMap (both main resources, created AFTER
    pre-install hooks complete). Post-install side-steps both by
    deferring to after all resources are loaded, at the cost of one
    pod restart on first install (~30-60s).
  - Two-image approach: bitnamilegacy/kubectl:1.29.9 (already in
    scope from postgres-migration-job) for kubectl containers;
    postgres:15 (same as job-init's db-check) for psql. No new image
    dependencies.

  Idempotency contract:
  - Secret + DB row both exist with matching token → no-op
  - Secret missing, DB row exists → regenerate token, UPDATE DB
    password, write Secret (token rotation path)
  - Secret exists, DB row missing → re-INSERT row with Secret's token
    (partial-state recovery)
  - Neither → generate token, INSERT, write Secret (first install)

  Smoke-tested end-to-end on a fresh test ns with vanilla postgres:15
  + pre-loaded minimal schema. All three scenarios pass:
  - Cold install: Job completes in 33s, Secret + DB row both produced,
    token round-trips byte-identical between Secret.data.token and
    users.password
  - Idempotent re-run: prepare-token reuses existing Secret's token,
    Secret + DB unchanged
  - Rotation (delete Secret only): fresh token generated, DB password
    updated via ON CONFLICT, new Secret written, old token != new

  * fix(adminAuth): address coderabbit review

  Three findings from CodeRabbit on PR #2:

  1. providerCredsSecretName default did not match documented contract.
     Code produced `<fullname>-provider-creds` (e.g. `hook-smoke-listmonk-provider-creds`
     for release `hook-smoke`), but docs claimed `<release>-provider-creds`.
     Resolution: switch the helper to use .Release.Name directly. Trade-off
     noted in the helper docstring — diverges from dbSecretName / smtpSecretName
     (which use listmonk.fullname) but matches the documented contract and is
     simpler for downstream composition consumers to predict.

  2. INSERT … ON CONFLICT … WHERE silently no-ops the UPDATE when the
     predicate is false. If a row exists with username='crossplane-provider'
     but type != 'api' (e.g. a previously-created interactive admin), the
     conflicting row would be left unchanged AND write-secret +
     restart-listmonk would still run, producing a Secret whose token doesn't
     match anything in the DB. Subsequent Basic-Auth would fail mysteriously.
     Resolution: added a Phase 3 type-collision guard that SELECTs the
     existing user's type and exits 1 with a clear diagnostic message before
     the UPSERT runs. The WHERE clause on ON CONFLICT is kept as
     belt-and-suspenders.

  3. values.yaml docs were internally inconsistent — opening sentence said
     "pre-install,pre-upgrade Hook" while the implementation block + idempotency
     section described post-install behavior, and a stale "No pod restart
     required" claim contradicted the actual rollout-restart step.
     Resolution: rewrote the adminAuth doc block to be consistently
     post-install/post-upgrade with rollout-restart, fixed the hook resources
     ordering description to reflect the real weight 0 (SA + RBAC) → weight 1
     (Job) split, added a new idempotency-contract row for the type-collision
     fail-fast case.

  Verified on pat-local with the same vanilla-postgres test harness:

  - Fail-fast: pre-create a type=user row named crossplane-provider, run the
    Job → write-db initContainer exits 1, message printed verbatim, Job marks
    failed=1.
  - Cold install (no pre-existing user): Job succeeds; Secret named
    `hook-smoke-provider-creds` (not `hook-smoke-listmonk-provider-creds`);
    users row created with type=api; Secret.token byte-identical to DB
    password.
  - Idempotent re-run (DB + Secret already in sync): prepare-token reuses
    existing Secret's token, type-collision guard sees type=api → passes,
    ON CONFLICT UPDATE writes same value (effective no-op). Token unchanged.

  * fix(adminAuth): type-collision guard uses psql -f - for safe param substitution

  CodeRabbit follow-up on PR #2: the previous fix-attempt
  (commit 237c05f) parameterized the SELECT with `psql -c -v
  username=… "SELECT … :'username'"`, but psql's `-c` mode does NOT
  process `:'variable'` substitution (only `-f` / stdin / interactive
  input does, per psql(1)). The substitution silently failed → SQL
  syntax error → stderr suppressed by `2>/dev/null` → empty
  EXISTING_TYPE → guard passed even on actual type collisions.

  Verified the silent failure mode on pat-local: pre-create a
  `type=user` row named `crossplane-provider`, run the hook, write-db
  exits 0 with "users row reconciled" but the ON CONFLICT … WHERE
  type='api' clause silently no-ops because the existing row's type !=
  'api'. Secret gets written with a token that doesn't match
  anything → Basic-Auth fails downstream.

  Fix: pipe the SELECT into `psql -f -` via echo. -f does process -v
  substitution. Re-verified on pat-local:

  - Fail-fast scenario: pre-existing type=user row → write-db logs
    "✗ user 'crossplane-provider' already exists with type='user';
    refusing to mutate" → exit code 1
  - Cold install: row created, INSERT 0 1
  - Idempotent re-run: reuse existing Secret's token, UPSERT writes
    same value


See full diff: [v0.1.1...v0.2.0](https://github.com/hops-ops/listmonk-chart/compare/v0.1.1...v0.2.0)
