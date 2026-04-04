# Security Notes

## Operational Rules

- verify the target environment before every push
- avoid ad-hoc remote changes that bypass verification scripts
- keep edge mail secrets aligned between Supabase and Apps Script

## Local Safety

- prefer `make start-local` for daily work because it is non-destructive
- use restore and mirror commands intentionally, not as a default startup path
