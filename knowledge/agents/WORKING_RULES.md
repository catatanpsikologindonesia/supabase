# Agent Working Rules

## Rules

- read `CURRENT_STATE.md` first for workflow-sensitive changes
- keep knowledge documents in English
- use `make start-local` as the default local entry point
- if local storage binaries change, run `make export-storage` before commit/push
- do not assume SMTP is still the active email path
- do not use `make mirror-remote-to-local` as the default fix for parity mismatch when local intentional changes are in progress
- update documentation when ports, commands, or delivery behavior change
