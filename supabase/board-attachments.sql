-- Public reads are required for shared board previews; anyone with an object URL can access that file.
insert into storage.buckets (id, name, public)
values ('board-attachments', 'board-attachments', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "Users can upload their board attachments"
on storage.objects;

create policy "Users can upload their board attachments"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'board-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Users can update their board attachments"
on storage.objects;

create policy "Users can update their board attachments"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'board-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'board-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Users can delete their board attachments"
on storage.objects;

create policy "Users can delete their board attachments"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'board-attachments'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
