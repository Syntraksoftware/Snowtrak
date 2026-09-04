-- Run this in the Supabase SQL editor after 021.
--
-- profiles.id references Supabase auth's `users`, but registration writes
-- `user_info`, so every insert fails with 23503 and the table has never held
-- a row: 41 users, 0 profiles. Every profile edit returns 500 and every
-- uploaded avatar URL is discarded.
--
-- Repairing it as-is would be worse. profiles is read by one file;
-- user_info is read by ten across three services, and every displayed name
-- already comes from it. Keeping full_name creates a second source for one
-- fact, and the profile screen and the feed would disagree silently.
--
-- One rule decides where a column lives: user_info holds what other services
-- read, profiles holds what only the profile screen reads.
--
-- Design: docs/superpowers/specs/2026-09-04-profiles-repair-design.md

begin;

alter table profiles drop constraint profiles_id_fkey;
alter table profiles add constraint profiles_id_fkey
  foreign key (id) references user_info(id) on delete cascade;

-- One profile per existing user. Ids only: usernames are chosen, never
-- generated. Deriving them from email addresses would mint handles nobody
-- picked, collide across domains, and leak the real names the field exists
-- to hide.
insert into profiles (id)
select id from user_info
on conflict (id) do nothing;

-- The second source for a name, removed before anything can write to it.
alter table profiles drop column full_name;

-- The displayed identity moves to where every service already reads. Unique
-- on lower(username) so SnowKing and snowking cannot both exist, and partial
-- so the null usernames do not collide with each other.
alter table user_info add column if not exists username text;
create unique index if not exists user_info_username_key
  on user_info (lower(username)) where username is not null;

alter table profiles drop column username;

commit;
