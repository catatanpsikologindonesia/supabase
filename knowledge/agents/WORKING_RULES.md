# Agent Working Rules

## Rules

- read `knowledge/CURRENT_STATE.md` before workflow-sensitive changes
- keep repo knowledge in English
- use `make start-local` as the default local runtime entry point
- use `make start-local-restore` when you explicitly need the committed DB snapshot restored first
- do not assume SMTP is active; current mail delivery goes through the GAS dispatcher
- do not use `make mirror-remote-to-local` as the default response to every parity mismatch
- update documentation whenever commands, ports, scripts, or backend delivery behavior change
