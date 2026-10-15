-- MyRSU Supabase schema.
-- Firebase Auth remains the identity provider. The Firebase UID is stored as text
-- and is used by the API after it verifies the Firebase ID token.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id text primary key,
  name text not null default '',
  email text not null default '',
  photo_url text,
  student_id text,
  major_id text,
  major_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.majors (
  id text primary key,
  name text not null,
  faculty text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.timetable_entries (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles(id) on delete cascade,
  code text not null default '',
  title text not null default '',
  section text not null default '',
  room text not null default '',
  instructor text not null default '',
  day smallint not null check (day between 0 and 6),
  start_minutes smallint not null check (start_minutes between 0 and 1439),
  end_minutes smallint not null check (end_minutes between 1 and 1440),
  color_index smallint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.personal_events (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles(id) on delete cascade,
  title text not null default '',
  notes text not null default '',
  event_date date not null,
  all_day boolean not null default true,
  start_minutes smallint check (start_minutes between 0 and 1439),
  end_minutes smallint check (end_minutes between 1 and 1440),
  location text not null default '',
  color_index smallint not null default 0,
  remind_day_before boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id text not null references public.profiles(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'web',
  updated_at timestamptz not null default now()
);

create index if not exists timetable_entries_user_day_idx
  on public.timetable_entries(user_id, day, start_minutes);
create index if not exists personal_events_user_date_idx
  on public.personal_events(user_id, event_date);
create index if not exists device_tokens_user_idx
  on public.device_tokens(user_id);

-- The API uses the service-role key and enforces ownership in server code.
-- Keep RLS enabled as defense in depth; do not expose the service-role key to Flutter.
alter table public.profiles enable row level security;
alter table public.majors enable row level security;
alter table public.timetable_entries enable row level security;
alter table public.personal_events enable row level security;
alter table public.device_tokens enable row level security;

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
drop trigger if exists timetable_set_updated_at on public.timetable_entries;
create trigger timetable_set_updated_at before update on public.timetable_entries
for each row execute function public.set_updated_at();
drop trigger if exists events_set_updated_at on public.personal_events;
create trigger events_set_updated_at before update on public.personal_events
for each row execute function public.set_updated_at();
