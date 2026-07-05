-- Supabase schema for the couple app.
-- Run this file in Supabase SQL Editor after creating the project.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Common helpers
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.prevent_column_updates()
returns trigger
language plpgsql
as $$
declare
  column_name text;
begin
  foreach column_name in array tg_argv loop
    if to_jsonb(old) ->> column_name is distinct from to_jsonb(new) ->> column_name then
      raise exception 'column "%" cannot be changed', column_name;
    end if;
  end loop;

  return new;
end;
$$;

create or replace function public.generate_invite_code()
returns text
language sql
as $$
  select string_agg(
    substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', (floor(random() * 32) + 1)::int, 1),
    ''
  )
  from generate_series(1, 6);
$$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null default 'User',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.couples (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references auth.users(id) on delete cascade,
  user_b_id uuid references auth.users(id) on delete cascade,
  invite_code text not null unique check (invite_code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  status text not null default 'pending'
    check (status in ('pending', 'active', 'archived')),
  created_at timestamptz not null default now(),
  paired_at timestamptz,
  archived_at timestamptz,
  updated_at timestamptz not null default now(),
  check (user_b_id is null or user_a_id <> user_b_id),
  check (status <> 'active' or user_b_id is not null)
);

create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  is_done boolean not null default false,
  created_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  issuer_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  description text,
  status text not null default 'unused' check (status in ('unused', 'used', 'cancelled')),
  expires_at date,
  source_request_id uuid,
  used_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (issuer_id <> receiver_id)
);

create table if not exists public.coupon_requests (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  requester_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  approver_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  description text,
  expires_at date,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  response_note text,
  coupon_id uuid references public.coupons(id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requester_id <> approver_id)
);

alter table public.coupons
  add column if not exists expires_at date;

alter table public.coupons
  add column if not exists source_request_id uuid;

do $$
begin
  alter table public.coupons
    add constraint coupons_source_request_fk
    foreign key (source_request_id)
    references public.coupon_requests(id)
    on delete set null;
exception
  when duplicate_object then null;
end $$;

create table if not exists public.journals (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  author_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entry_date date not null default current_date,
  mood text,
  content text not null check (length(trim(content)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.anniversaries (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  event_date date not null,
  type text not null default 'custom'
    check (type in ('together', 'birthday', 'custom')),
  repeat_yearly boolean not null default false,
  created_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meal_entries (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  author_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  meal_date date not null default current_date,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  photo_path text not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  meal_date date not null default current_date,
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  content text not null check (length(trim(content)) > 0),
  is_done boolean not null default false,
  created_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

create index if not exists couples_user_a_idx on public.couples(user_a_id);
create index if not exists couples_user_b_idx on public.couples(user_b_id);
create index if not exists couples_status_idx on public.couples(status);
create index if not exists couples_pending_invite_idx
  on public.couples(invite_code)
  where status = 'pending';
create unique index if not exists couples_open_user_a_unique_idx
  on public.couples(user_a_id)
  where status in ('pending', 'active');
create unique index if not exists couples_open_user_b_unique_idx
  on public.couples(user_b_id)
  where status in ('pending', 'active') and user_b_id is not null;

create index if not exists todos_couple_created_idx
  on public.todos(couple_id, created_at desc);
create index if not exists coupons_couple_created_idx
  on public.coupons(couple_id, created_at desc);
create index if not exists coupons_receiver_status_idx
  on public.coupons(receiver_id, status);
create index if not exists coupons_expires_idx
  on public.coupons(couple_id, expires_at);
create index if not exists coupon_requests_couple_created_idx
  on public.coupon_requests(couple_id, created_at desc);
create index if not exists coupon_requests_approver_status_idx
  on public.coupon_requests(approver_id, status);
create index if not exists coupon_requests_requester_status_idx
  on public.coupon_requests(requester_id, status);
create index if not exists journals_couple_date_idx
  on public.journals(couple_id, entry_date desc, created_at desc);
create index if not exists anniversaries_couple_date_idx
  on public.anniversaries(couple_id, event_date);
create index if not exists meal_entries_couple_date_idx
  on public.meal_entries(couple_id, meal_date desc, meal_type);
create index if not exists meal_plans_couple_date_idx
  on public.meal_plans(couple_id, meal_date desc, meal_type);

-- ---------------------------------------------------------------------------
-- Security helper functions
-- ---------------------------------------------------------------------------

create or replace function public.user_has_open_couple(target_user_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.couples c
    where c.status in ('pending', 'active')
      and (c.user_a_id = target_user_id or c.user_b_id = target_user_id)
  );
$$;

create or replace function public.is_couple_member(target_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.couples c
    where c.id = target_couple_id
      and c.status = 'active'
      and auth.uid() in (c.user_a_id, c.user_b_id)
  );
$$;

create or replace function public.is_couple_partner(
  target_couple_id uuid,
  target_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.couples c
    where c.id = target_couple_id
      and c.status = 'active'
      and auth.uid() in (c.user_a_id, c.user_b_id)
      and target_user_id in (c.user_a_id, c.user_b_id)
      and target_user_id <> auth.uid()
  );
$$;

create or replace function public.is_visible_profile(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_user_id = auth.uid()
    or exists (
      select 1
      from public.couples c
      where c.status = 'active'
        and auth.uid() in (c.user_a_id, c.user_b_id)
        and target_user_id in (c.user_a_id, c.user_b_id)
    );
$$;

create or replace function public.can_access_meal_object(object_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  target_couple_id uuid;
begin
  target_couple_id := split_part(object_name, '/', 1)::uuid;
  return public.is_couple_member(target_couple_id);
exception
  when others then
    return false;
end;
$$;

create or replace function public.can_manage_own_meal_object(object_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  target_couple_id uuid;
  target_user_id uuid;
begin
  target_couple_id := split_part(object_name, '/', 1)::uuid;
  target_user_id := split_part(object_name, '/', 2)::uuid;
  return public.is_couple_member(target_couple_id)
    and target_user_id = auth.uid();
exception
  when others then
    return false;
end;
$$;

-- ---------------------------------------------------------------------------
-- Business RPC functions
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nickname, avatar_url)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'nickname', ''), 'User'),
    nullif(new.raw_user_meta_data ->> 'avatar_url', '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create or replace function public.create_couple_invite()
returns table (id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_code text;
  new_id uuid;
begin
  if current_user_id is null then
    raise exception 'not authenticated';
  end if;

  if public.user_has_open_couple(current_user_id) then
    raise exception 'user already has an active or pending couple';
  end if;

  loop
    new_code := public.generate_invite_code();

    begin
      insert into public.couples (user_a_id, invite_code, status)
      values (current_user_id, new_code, 'pending')
      returning couples.id into new_id;

      return query select new_id, new_code;
      return;
    exception
      when unique_violation then
        -- Retry on rare invite-code collision.
    end;
  end loop;
end;
$$;

create or replace function public.bind_couple(invite_code_input text)
returns table (
  id uuid,
  user_a_id uuid,
  user_b_id uuid,
  invite_code text,
  status text,
  paired_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target public.couples%rowtype;
  normalized_code text := upper(trim(invite_code_input));
begin
  if current_user_id is null then
    raise exception 'not authenticated';
  end if;

  if normalized_code is null or normalized_code = '' then
    raise exception 'invite code is required';
  end if;

  select *
  into target
  from public.couples c
  where c.invite_code = normalized_code
    and c.status = 'pending'
  for update;

  if not found then
    raise exception 'invalid or used invite code';
  end if;

  if target.user_a_id = current_user_id then
    raise exception 'cannot bind with your own invite code';
  end if;

  if public.user_has_open_couple(current_user_id) then
    raise exception 'user already has an active or pending couple';
  end if;

  update public.couples c
  set user_b_id = current_user_id,
      status = 'active',
      paired_at = now(),
      updated_at = now()
  where c.id = target.id
  returning c.id, c.user_a_id, c.user_b_id, c.invite_code, c.status, c.paired_at
  into id, user_a_id, user_b_id, invite_code, status, paired_at;

  return next;
end;
$$;

create or replace function public.use_coupon(coupon_id_input uuid)
returns public.coupons
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target public.coupons%rowtype;
begin
  if current_user_id is null then
    raise exception 'not authenticated';
  end if;

  select *
  into target
  from public.coupons c
  where c.id = coupon_id_input
  for update;

  if not found then
    raise exception 'coupon not found';
  end if;

  if target.receiver_id <> current_user_id then
    raise exception 'only the receiver can use this coupon';
  end if;

  if not public.is_couple_member(target.couple_id) then
    raise exception 'not allowed';
  end if;

  if target.status <> 'unused' then
    raise exception 'coupon is not unused';
  end if;

  if target.expires_at is not null and target.expires_at < current_date then
    raise exception 'coupon is expired';
  end if;

  update public.coupons c
  set status = 'used',
      used_at = now(),
      updated_at = now()
  where c.id = target.id
  returning * into target;

  return target;
end;
$$;

create or replace function public.respond_coupon_request(
  request_id_input uuid,
  approve_input boolean,
  response_note_input text default null
)
returns public.coupon_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target public.coupon_requests%rowtype;
  new_coupon_id uuid;
begin
  if current_user_id is null then
    raise exception 'not authenticated';
  end if;

  select *
  into target
  from public.coupon_requests r
  where r.id = request_id_input
  for update;

  if not found then
    raise exception 'coupon request not found';
  end if;

  if target.approver_id <> current_user_id then
    raise exception 'only the approver can respond';
  end if;

  if not public.is_couple_member(target.couple_id) then
    raise exception 'not allowed';
  end if;

  if target.status <> 'pending' then
    raise exception 'coupon request is not pending';
  end if;

  if approve_input
     and target.expires_at is not null
     and target.expires_at < current_date then
    raise exception 'coupon request has expired';
  end if;

  if approve_input then
    insert into public.coupons (
      couple_id,
      issuer_id,
      receiver_id,
      title,
      description,
      expires_at,
      source_request_id
    )
    values (
      target.couple_id,
      current_user_id,
      target.requester_id,
      target.title,
      target.description,
      target.expires_at,
      target.id
    )
    returning id into new_coupon_id;

    update public.coupon_requests r
    set status = 'approved',
        response_note = nullif(trim(response_note_input), ''),
        coupon_id = new_coupon_id,
        decided_at = now(),
        updated_at = now()
    where r.id = target.id
    returning * into target;
  else
    update public.coupon_requests r
    set status = 'rejected',
        response_note = nullif(trim(response_note_input), ''),
        decided_at = now(),
        updated_at = now()
    where r.id = target.id
    returning * into target;
  end if;

  return target;
end;
$$;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists couples_set_updated_at on public.couples;
create trigger couples_set_updated_at
  before update on public.couples
  for each row execute function public.set_updated_at();

drop trigger if exists todos_set_updated_at on public.todos;
create trigger todos_set_updated_at
  before update on public.todos
  for each row execute function public.set_updated_at();

drop trigger if exists coupons_set_updated_at on public.coupons;
create trigger coupons_set_updated_at
  before update on public.coupons
  for each row execute function public.set_updated_at();

drop trigger if exists coupon_requests_set_updated_at on public.coupon_requests;
create trigger coupon_requests_set_updated_at
  before update on public.coupon_requests
  for each row execute function public.set_updated_at();

drop trigger if exists journals_set_updated_at on public.journals;
create trigger journals_set_updated_at
  before update on public.journals
  for each row execute function public.set_updated_at();

drop trigger if exists anniversaries_set_updated_at on public.anniversaries;
create trigger anniversaries_set_updated_at
  before update on public.anniversaries
  for each row execute function public.set_updated_at();

drop trigger if exists meal_entries_set_updated_at on public.meal_entries;
create trigger meal_entries_set_updated_at
  before update on public.meal_entries
  for each row execute function public.set_updated_at();

drop trigger if exists meal_plans_set_updated_at on public.meal_plans;
create trigger meal_plans_set_updated_at
  before update on public.meal_plans
  for each row execute function public.set_updated_at();

drop trigger if exists todos_prevent_identity_update on public.todos;
create trigger todos_prevent_identity_update
  before update on public.todos
  for each row execute function public.prevent_column_updates('couple_id', 'created_by');

drop trigger if exists coupons_prevent_identity_update on public.coupons;
create trigger coupons_prevent_identity_update
  before update on public.coupons
  for each row execute function public.prevent_column_updates('couple_id', 'issuer_id', 'receiver_id');

drop trigger if exists coupon_requests_prevent_identity_update on public.coupon_requests;
create trigger coupon_requests_prevent_identity_update
  before update on public.coupon_requests
  for each row execute function public.prevent_column_updates('couple_id', 'requester_id', 'approver_id');

drop trigger if exists journals_prevent_identity_update on public.journals;
create trigger journals_prevent_identity_update
  before update on public.journals
  for each row execute function public.prevent_column_updates('couple_id', 'author_id');

drop trigger if exists anniversaries_prevent_identity_update on public.anniversaries;
create trigger anniversaries_prevent_identity_update
  before update on public.anniversaries
  for each row execute function public.prevent_column_updates('couple_id', 'created_by');

drop trigger if exists meal_entries_prevent_identity_update on public.meal_entries;
create trigger meal_entries_prevent_identity_update
  before update on public.meal_entries
  for each row execute function public.prevent_column_updates('couple_id', 'author_id', 'photo_path');

drop trigger if exists meal_plans_prevent_identity_update on public.meal_plans;
create trigger meal_plans_prevent_identity_update
  before update on public.meal_plans
  for each row execute function public.prevent_column_updates('couple_id', 'created_by');

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.couples enable row level security;
alter table public.todos enable row level security;
alter table public.coupons enable row level security;
alter table public.coupon_requests enable row level security;
alter table public.journals enable row level security;
alter table public.anniversaries enable row level security;
alter table public.meal_entries enable row level security;
alter table public.meal_plans enable row level security;

drop policy if exists "profiles_select_visible" on public.profiles;
create policy "profiles_select_visible"
on public.profiles for select
to authenticated
using (public.is_visible_profile(id));

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "profiles_delete_self" on public.profiles;
create policy "profiles_delete_self"
on public.profiles for delete
to authenticated
using (id = auth.uid());

drop policy if exists "couples_select_own" on public.couples;
create policy "couples_select_own"
on public.couples for select
to authenticated
using (auth.uid() in (user_a_id, user_b_id));

drop policy if exists "todos_select_couple" on public.todos;
create policy "todos_select_couple"
on public.todos for select
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "todos_insert_couple" on public.todos;
create policy "todos_insert_couple"
on public.todos for insert
to authenticated
with check (
  public.is_couple_member(couple_id)
  and created_by = auth.uid()
);

drop policy if exists "todos_update_couple" on public.todos;
create policy "todos_update_couple"
on public.todos for update
to authenticated
using (public.is_couple_member(couple_id))
with check (public.is_couple_member(couple_id));

drop policy if exists "todos_delete_couple" on public.todos;
create policy "todos_delete_couple"
on public.todos for delete
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "coupons_select_couple" on public.coupons;
create policy "coupons_select_couple"
on public.coupons for select
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "coupons_insert_to_partner" on public.coupons;
create policy "coupons_insert_to_partner"
on public.coupons for insert
to authenticated
with check (
  public.is_couple_member(couple_id)
  and issuer_id = auth.uid()
  and public.is_couple_partner(couple_id, receiver_id)
  and status = 'unused'
  and source_request_id is null
  and used_at is null
  and (expires_at is null or expires_at >= current_date)
);

drop policy if exists "coupon_requests_select_couple" on public.coupon_requests;
create policy "coupon_requests_select_couple"
on public.coupon_requests for select
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "coupon_requests_insert_to_partner" on public.coupon_requests;
create policy "coupon_requests_insert_to_partner"
on public.coupon_requests for insert
to authenticated
with check (
  public.is_couple_member(couple_id)
  and requester_id = auth.uid()
  and public.is_couple_partner(couple_id, approver_id)
  and status = 'pending'
  and coupon_id is null
  and decided_at is null
  and (expires_at is null or expires_at >= current_date)
);

drop policy if exists "journals_select_couple" on public.journals;
create policy "journals_select_couple"
on public.journals for select
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "journals_insert_author" on public.journals;
create policy "journals_insert_author"
on public.journals for insert
to authenticated
with check (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
);

drop policy if exists "journals_update_author" on public.journals;
create policy "journals_update_author"
on public.journals for update
to authenticated
using (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
)
with check (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
);

drop policy if exists "journals_delete_author" on public.journals;
create policy "journals_delete_author"
on public.journals for delete
to authenticated
using (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
);

drop policy if exists "anniversaries_select_couple" on public.anniversaries;
create policy "anniversaries_select_couple"
on public.anniversaries for select
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "anniversaries_insert_couple" on public.anniversaries;
create policy "anniversaries_insert_couple"
on public.anniversaries for insert
to authenticated
with check (
  public.is_couple_member(couple_id)
  and created_by = auth.uid()
);

drop policy if exists "anniversaries_update_couple" on public.anniversaries;
create policy "anniversaries_update_couple"
on public.anniversaries for update
to authenticated
using (public.is_couple_member(couple_id))
with check (public.is_couple_member(couple_id));

drop policy if exists "anniversaries_delete_couple" on public.anniversaries;
create policy "anniversaries_delete_couple"
on public.anniversaries for delete
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "meal_entries_select_couple" on public.meal_entries;
create policy "meal_entries_select_couple"
on public.meal_entries for select
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "meal_entries_insert_author" on public.meal_entries;
create policy "meal_entries_insert_author"
on public.meal_entries for insert
to authenticated
with check (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
);

drop policy if exists "meal_entries_update_author" on public.meal_entries;
create policy "meal_entries_update_author"
on public.meal_entries for update
to authenticated
using (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
)
with check (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
);

drop policy if exists "meal_entries_delete_author" on public.meal_entries;
create policy "meal_entries_delete_author"
on public.meal_entries for delete
to authenticated
using (
  public.is_couple_member(couple_id)
  and author_id = auth.uid()
);

drop policy if exists "meal_plans_select_couple" on public.meal_plans;
create policy "meal_plans_select_couple"
on public.meal_plans for select
to authenticated
using (public.is_couple_member(couple_id));

drop policy if exists "meal_plans_insert_couple" on public.meal_plans;
create policy "meal_plans_insert_couple"
on public.meal_plans for insert
to authenticated
with check (
  public.is_couple_member(couple_id)
  and created_by = auth.uid()
);

drop policy if exists "meal_plans_update_couple" on public.meal_plans;
create policy "meal_plans_update_couple"
on public.meal_plans for update
to authenticated
using (public.is_couple_member(couple_id))
with check (public.is_couple_member(couple_id));

drop policy if exists "meal_plans_delete_couple" on public.meal_plans;
create policy "meal_plans_delete_couple"
on public.meal_plans for delete
to authenticated
using (public.is_couple_member(couple_id));

-- ---------------------------------------------------------------------------
-- Storage policies for private meal photos
-- Path format: {couple_id}/{user_id}/{file_name}
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('meals', 'meals', false)
on conflict (id) do nothing;

drop policy if exists "meal_photos_select_couple" on storage.objects;
create policy "meal_photos_select_couple"
on storage.objects for select
to authenticated
using (
  bucket_id = 'meals'
  and public.can_access_meal_object(name)
);

drop policy if exists "meal_photos_insert_own" on storage.objects;
create policy "meal_photos_insert_own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'meals'
  and public.can_manage_own_meal_object(name)
);

drop policy if exists "meal_photos_delete_own" on storage.objects;
create policy "meal_photos_delete_own"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'meals'
  and public.can_manage_own_meal_object(name)
);

-- ---------------------------------------------------------------------------
-- Realtime setup
-- ---------------------------------------------------------------------------

alter table public.todos replica identity full;
alter table public.coupons replica identity full;
alter table public.coupon_requests replica identity full;
alter table public.journals replica identity full;
alter table public.anniversaries replica identity full;
alter table public.meal_entries replica identity full;
alter table public.meal_plans replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.todos;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.coupons;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.coupon_requests;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.journals;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.anniversaries;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.meal_entries;
exception
  when duplicate_object or undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.meal_plans;
exception
  when duplicate_object or undefined_object then null;
end $$;

-- ---------------------------------------------------------------------------
-- Function permissions
-- ---------------------------------------------------------------------------

revoke execute on function public.set_updated_at() from public;
revoke execute on function public.prevent_column_updates() from public;
revoke execute on function public.generate_invite_code() from public;
revoke execute on function public.user_has_open_couple(uuid) from public;
revoke execute on function public.handle_new_user() from public;

revoke execute on function public.is_couple_member(uuid) from public;
revoke execute on function public.is_couple_partner(uuid, uuid) from public;
revoke execute on function public.is_visible_profile(uuid) from public;
revoke execute on function public.can_access_meal_object(text) from public;
revoke execute on function public.can_manage_own_meal_object(text) from public;

revoke execute on function public.create_couple_invite() from public;
revoke execute on function public.bind_couple(text) from public;
revoke execute on function public.use_coupon(uuid) from public;
revoke execute on function public.respond_coupon_request(uuid, boolean, text) from public;

grant execute on function public.is_couple_member(uuid) to authenticated;
grant execute on function public.is_couple_partner(uuid, uuid) to authenticated;
grant execute on function public.is_visible_profile(uuid) to authenticated;
grant execute on function public.can_access_meal_object(text) to authenticated;
grant execute on function public.can_manage_own_meal_object(text) to authenticated;

grant execute on function public.create_couple_invite() to authenticated;
grant execute on function public.bind_couple(text) to authenticated;
grant execute on function public.use_coupon(uuid) to authenticated;
grant execute on function public.respond_coupon_request(uuid, boolean, text) to authenticated;
