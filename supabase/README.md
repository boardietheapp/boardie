# Supabase setup

The migration files are the source of truth for database changes. The production schema baseline in `migrations/20261126155816_remote_schema.sql` has already been recorded as applied. Do not edit that baseline; add later changes as new timestamped migrations.

Review a migration before applying it to the linked production project:

```sh
npx supabase db push --remote --dry-run
npx supabase db push --remote
```

The first command previews pending migrations. The second applies them. Do not commit `supabase/.temp`; it contains machine-specific CLI state.

Also configure Supabase **Authentication → URL Configuration** with the correct local development and production site URLs and redirect URLs. Signup redirects to `studio.html`.

The `board-attachments` bucket is public so shared board previews can display attachments. Anyone with an attachment URL can access that file; do not upload sensitive documents.

Only the Supabase publishable key belongs in browser code. Never expose a service-role key or database password in the app.
