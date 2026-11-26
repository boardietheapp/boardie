create table if not exists public.newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  name text,
  email text not null unique,
  created_at timestamptz not null default now()
);

alter table public.newsletter_subscribers enable row level security;

revoke all privileges on table public.newsletter_subscribers
from public, anon, authenticated;

grant usage on schema public to anon, authenticated;
grant insert on table public.newsletter_subscribers to anon, authenticated;

drop policy if exists "Public can subscribe to newsletter"
on public.newsletter_subscribers;

create policy "Public can subscribe to newsletter"
on public.newsletter_subscribers
for insert
to anon, authenticated
with check (email = lower(btrim(email)));
