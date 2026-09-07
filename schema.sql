-- Deskball Federation — Supabase schema
-- Paste this whole file into the Supabase SQL editor and press Run.
-- Safe to run more than once.

-- ---------------------------------------------------------------- tables
create table if not exists public.league (
  id          int primary key,
  data        jsonb       not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);
insert into public.league (id, data) values (1, '{}'::jsonb)
  on conflict (id) do nothing;

-- Being in this table is what makes someone the admin. There is deliberately
-- no way to add yourself through the app — you add your row in the dashboard.
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create table if not exists public.requests (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  kind        text        not null check (kind in ('join','skill')),
  status      text        not null default 'pending' check (status in ('pending','approved','declined')),
  payload     jsonb       not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);
create index if not exists requests_status_idx on public.requests (status, created_at desc);

-- security definer, so checking "am I an admin" does not re-trigger RLS on admins
create or replace function public.is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- ------------------------------------------------------------------- RLS
alter table public.league   enable row level security;
alter table public.admins   enable row level security;
alter table public.requests enable row level security;

drop policy if exists "league read"    on public.league;
drop policy if exists "league insert"  on public.league;
drop policy if exists "league update"  on public.league;
drop policy if exists "admins read"    on public.admins;
drop policy if exists "req insert own" on public.requests;
drop policy if exists "req read"       on public.requests;
drop policy if exists "req update"     on public.requests;
drop policy if exists "req delete"     on public.requests;

-- Anyone signed in can read the league. Only an admin can change it.
create policy "league read"   on public.league for select to authenticated using (true);
create policy "league insert" on public.league for insert to authenticated with check (public.is_admin());
create policy "league update" on public.league for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- Readable so the app knows whether you are the admin. No writes over the API.
create policy "admins read" on public.admins for select to authenticated using (true);

-- You may file your own requests and see your own. Admins see and settle all.
create policy "req insert own" on public.requests for insert to authenticated
  with check (user_id = auth.uid());
create policy "req read"   on public.requests for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy "req update" on public.requests for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy "req delete" on public.requests for delete to authenticated
  using (public.is_admin());

-- -------------------------------------------------------------- realtime
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.league';
  exception when duplicate_object then null; end;
  begin execute 'alter publication supabase_realtime add table public.requests';
  exception when duplicate_object then null; end;
end $$;
