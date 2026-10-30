-- NEXTLIB core library schema migration
-- Apply in Supabase SQL Editor. Safe to re-run for the objects defined here.
-- This migration deliberately does not create an initial administrator account.

create extension if not exists pgcrypto;

do $$ begin
  create type public.nextlib_role as enum ('admin', 'librarian', 'member');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.loan_status as enum ('issued', 'returned', 'overdue', 'lost');
exception when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role public.nextlib_role not null default 'member',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text not null,
  category text not null default 'Computer Science',
  isbn text unique,
  copies_total integer not null default 1 check (copies_total >= 0),
  copies_available integer not null default 1 check (copies_available >= 0 and copies_available <= copies_total),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete set null,
  member_number text not null unique,
  full_name text not null,
  email text,
  phone text,
  department text,
  programme text,
  level text,
  member_type text not null default 'student' check (member_type in ('student','staff','faculty','external')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.book_copies (
  id uuid primary key default gen_random_uuid(),
  book_id uuid not null references public.books(id) on delete restrict,
  accession_number text not null unique,
  barcode text unique,
  status text not null default 'available' check (status in ('available','issued','maintenance','lost','withdrawn')),
  shelf_location text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(),
  copy_id uuid not null references public.book_copies(id) on delete restrict,
  member_id uuid not null references public.members(id) on delete restrict,
  issued_by uuid references public.profiles(id) on delete set null,
  returned_to uuid references public.profiles(id) on delete set null,
  issued_at timestamptz not null default now(),
  due_at timestamptz not null,
  returned_at timestamptz,
  status public.loan_status not null default 'issued',
  fine_amount numeric(12,2) not null default 0 check (fine_amount >= 0),
  notes text,
  created_at timestamptz not null default now(),
  check (due_at > issued_at),
  check ((status = 'returned' and returned_at is not null) or status <> 'returned')
);

create unique index if not exists loans_one_open_loan_per_copy
  on public.loans(copy_id) where returned_at is null and status in ('issued','overdue');

create index if not exists books_title_idx on public.books using btree (title);
create index if not exists books_category_idx on public.books using btree (category);
create index if not exists members_member_number_idx on public.members using btree (member_number);
create index if not exists loans_member_id_idx on public.loans using btree (member_id);
create index if not exists loans_due_at_idx on public.loans using btree (due_at);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.nextlib_is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin','librarian')
  );
$$;

create or replace function public.nextlib_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.books enable row level security;
alter table public.members enable row level security;
alter table public.book_copies enable row level security;
alter table public.loans enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists "Profiles are readable by owner or staff" on public.profiles;
create policy "Profiles are readable by owner or staff"
  on public.profiles for select to authenticated
  using (id = auth.uid() or public.nextlib_is_staff());

drop policy if exists "Staff can manage profiles" on public.profiles;
create policy "Staff can manage profiles"
  on public.profiles for all to authenticated
  using (public.nextlib_is_admin()) with check (public.nextlib_is_admin());

drop policy if exists "Authenticated staff can read books" on public.books;
drop policy if exists "Authenticated staff can add books" on public.books;
drop policy if exists "Authenticated staff can update books" on public.books;
drop policy if exists "Staff can read books" on public.books;
create policy "Staff can read books" on public.books
  for select to authenticated using (public.nextlib_is_staff());

drop policy if exists "Staff can insert books" on public.books;
create policy "Staff can insert books" on public.books
  for insert to authenticated with check (public.nextlib_is_staff());

drop policy if exists "Staff can update books" on public.books;
create policy "Staff can update books" on public.books
  for update to authenticated using (public.nextlib_is_staff()) with check (public.nextlib_is_staff());

drop policy if exists "Admins can delete books" on public.books;
create policy "Admins can delete books" on public.books
  for delete to authenticated using (public.nextlib_is_admin());

drop policy if exists "Staff can manage members" on public.members;
create policy "Staff can manage members" on public.members
  for all to authenticated using (public.nextlib_is_staff()) with check (public.nextlib_is_staff());

drop policy if exists "Staff can manage book copies" on public.book_copies;
create policy "Staff can manage book copies" on public.book_copies
  for all to authenticated using (public.nextlib_is_staff()) with check (public.nextlib_is_staff());

drop policy if exists "Staff can manage loans" on public.loans;
create policy "Staff can manage loans" on public.loans
  for all to authenticated using (public.nextlib_is_staff()) with check (public.nextlib_is_staff());

drop policy if exists "Staff can read audit logs" on public.audit_logs;
create policy "Staff can read audit logs" on public.audit_logs
  for select to authenticated using (public.nextlib_is_staff());

drop policy if exists "Staff can write audit logs" on public.audit_logs;
create policy "Staff can write audit logs" on public.audit_logs
  for insert to authenticated with check (public.nextlib_is_staff());

-- Keep updated_at current on mutable records.
create or replace function public.nextlib_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['profiles','books','members','book_copies'] loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format('create trigger set_updated_at before update on public.%I for each row execute function public.nextlib_set_updated_at()', t);
  end loop;
end $$;

-- New auth users receive a basic member profile. Privileged roles must be
-- assigned by an administrator through the Supabase dashboard/secure process.
create or replace function public.nextlib_create_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.email));
  return new;
end;
$$;

drop trigger if exists nextlib_on_auth_user_created on auth.users;
create trigger nextlib_on_auth_user_created
  after insert on auth.users
  for each row execute function public.nextlib_create_profile();
