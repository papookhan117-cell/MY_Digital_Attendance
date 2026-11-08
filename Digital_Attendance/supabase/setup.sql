-- Digital Attendance shared sync schema for Supabase Free.
-- Never put the service_role key in this PWA. Use only the publishable/anon key and authenticated users.
create table if not exists public.da_employees (
  owner_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  name text not null,
  mobile text not null default '',
  active boolean not null default true,
  qr_value text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (owner_id, id)
);

create table if not exists public.da_attendance (
  owner_id uuid not null references auth.users(id) on delete cascade,
  key text not null,
  employee_id text not null,
  employee_name text not null,
  date date not null,
  check_in text not null,
  check_out text,
  status text not null check (status in ('Present','Late','Absent')),
  method text not null check (method in ('Face','QR')),
  check_out_method text check (check_out_method is null or check_out_method in ('Face','QR')),
  device_id text not null,
  updated_at timestamptz not null default now(),
  primary key (owner_id, key),
  unique (owner_id, employee_id, date)
);

create table if not exists public.da_attendance_deletions (
  owner_id uuid not null references auth.users(id) on delete cascade,
  key text not null,
  deleted_at timestamptz not null default now(),
  device_id text not null,
  primary key (owner_id, key)
);

alter table public.da_employees enable row level security;
alter table public.da_attendance enable row level security;
alter table public.da_attendance_deletions enable row level security;
revoke all on public.da_employees, public.da_attendance, public.da_attendance_deletions from anon;
grant select, insert, update, delete on public.da_employees, public.da_attendance, public.da_attendance_deletions to authenticated;

drop policy if exists da_employees_select on public.da_employees;
create policy da_employees_select on public.da_employees for select to authenticated using ((select auth.uid()) = owner_id);
drop policy if exists da_employees_insert on public.da_employees;
create policy da_employees_insert on public.da_employees for insert to authenticated with check ((select auth.uid()) = owner_id);
drop policy if exists da_employees_update on public.da_employees;
create policy da_employees_update on public.da_employees for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
drop policy if exists da_employees_delete on public.da_employees;
create policy da_employees_delete on public.da_employees for delete to authenticated using ((select auth.uid()) = owner_id);

drop policy if exists da_attendance_select on public.da_attendance;
create policy da_attendance_select on public.da_attendance for select to authenticated using ((select auth.uid()) = owner_id);
drop policy if exists da_attendance_insert on public.da_attendance;
create policy da_attendance_insert on public.da_attendance for insert to authenticated with check ((select auth.uid()) = owner_id);
drop policy if exists da_attendance_update on public.da_attendance;
create policy da_attendance_update on public.da_attendance for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
drop policy if exists da_attendance_delete on public.da_attendance;
create policy da_attendance_delete on public.da_attendance for delete to authenticated using ((select auth.uid()) = owner_id);

drop policy if exists da_deletions_select on public.da_attendance_deletions;
create policy da_deletions_select on public.da_attendance_deletions for select to authenticated using ((select auth.uid()) = owner_id);
drop policy if exists da_deletions_insert on public.da_attendance_deletions;
create policy da_deletions_insert on public.da_attendance_deletions for insert to authenticated with check ((select auth.uid()) = owner_id);
drop policy if exists da_deletions_update on public.da_attendance_deletions;
create policy da_deletions_update on public.da_attendance_deletions for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
drop policy if exists da_deletions_delete on public.da_attendance_deletions;
create policy da_deletions_delete on public.da_attendance_deletions for delete to authenticated using ((select auth.uid()) = owner_id);

create index if not exists da_attendance_owner_date_idx on public.da_attendance (owner_id, date);
-- Schema additions for staff schedules, late and absent records. Safe to run on an existing project.
alter table public.da_employees add column if not exists schedule_category text not null default 'peon';
alter table public.da_employees add column if not exists photo_data text;
alter table public.da_employees add column if not exists gender text not null default '';

alter table public.da_attendance alter column check_in set default '';
alter table public.da_attendance alter column check_in drop not null;
alter table public.da_attendance add column if not exists late_minutes integer not null default 0;
alter table public.da_attendance add column if not exists late_seconds integer not null default 0;
alter table public.da_attendance add column if not exists scheduled_time text not null default '';
alter table public.da_attendance add column if not exists grace_minutes integer not null default 0;
alter table public.da_attendance drop constraint if exists da_attendance_status_check;
alter table public.da_attendance add constraint da_attendance_status_check check (status in ('Present','Late','Absent'));
alter table public.da_attendance drop constraint if exists da_attendance_method_check;
alter table public.da_attendance add constraint da_attendance_method_check check (method in ('Face','QR','Manual'));
create table if not exists public.da_settings (
  owner_id uuid not null references auth.users(id) on delete cascade,
  key text not null,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (owner_id,key)
);
alter table public.da_settings enable row level security;
revoke all on public.da_settings from anon;
grant select,insert,update,delete on public.da_settings to authenticated;
drop policy if exists da_settings_select on public.da_settings;
create policy da_settings_select on public.da_settings for select to authenticated using ((select auth.uid())=owner_id);
drop policy if exists da_settings_insert on public.da_settings;
create policy da_settings_insert on public.da_settings for insert to authenticated with check ((select auth.uid())=owner_id);
drop policy if exists da_settings_update on public.da_settings;
create policy da_settings_update on public.da_settings for update to authenticated using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
drop policy if exists da_settings_delete on public.da_settings;
create policy da_settings_delete on public.da_settings for delete to authenticated using ((select auth.uid())=owner_id);

-- Enable instant cross-device refresh through Supabase Realtime.
alter table public.da_employees replica identity full;
alter table public.da_attendance replica identity full;
alter table public.da_settings replica identity full;
do $$ begin alter publication supabase_realtime add table public.da_employees; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.da_attendance; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.da_settings; exception when duplicate_object then null; end $$;
