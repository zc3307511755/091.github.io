-- Run once in the Supabase SQL Editor to enable meal photo comments.

create table if not exists public.meal_comments (
  id uuid primary key default gen_random_uuid(),
  meal_entry_id uuid not null references public.meal_entries(id) on delete cascade,
  couple_id uuid not null references public.couples(id) on delete cascade,
  author_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  content text not null check (
    length(trim(content)) > 0 and length(trim(content)) <= 300
  ),
  created_at timestamptz not null default now()
);

create index if not exists meal_comments_entry_created_idx
  on public.meal_comments(meal_entry_id, created_at);
create index if not exists meal_comments_couple_created_idx
  on public.meal_comments(couple_id, created_at desc);

alter table public.meal_comments enable row level security;

drop policy if exists "meal_comments_select_couple" on public.meal_comments;
create policy "meal_comments_select_couple"
on public.meal_comments for select
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "meal_comments_insert_author" on public.meal_comments;
create policy "meal_comments_insert_author"
on public.meal_comments for insert
to authenticated
with check (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
  and exists (
    select 1
    from public.meal_entries entry
    where entry.id = meal_comments.meal_entry_id
      and entry.couple_id = meal_comments.couple_id
  )
);

drop policy if exists "meal_comments_delete_author" on public.meal_comments;
create policy "meal_comments_delete_author"
on public.meal_comments for delete
to authenticated
using (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
);

alter table public.meal_comments replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.meal_comments;
exception
  when duplicate_object or undefined_object then null;
end $$;
