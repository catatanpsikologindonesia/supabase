# Operations Guide

## Core model

- Remote Supabase is the active shared environment.
- Local Supabase mirror is used for safe iteration and validation.
- Pushes to remote must be explicit and guarded.

## Source of truth

- Runtime schema/data parity target: remote <-> local (verified via scripts).
- Edge Functions runtime source for deployment: `supabase/functions/*`.
- Push safety gate: `scripts/push_remote_changes.sh`.

## Standard workflow

### 1) Refresh local mirror from remote

```bash
make mirror-remote-to-local
```

### 2) Verify parity

```bash
make verify-local-remote
```

### 3) Apply local changes

Modify SQL/functions/files as required.

### 4) Push to staging

```bash
make push-staging
```

### 5) Push to production (after staging validation)

```bash
make push-prod
```

## Important behavior

- Push performs preflight verify.
- If mismatch is found, push asks for confirmation (`yes/no`).
- Push also creates a backup snapshot before deploying.
