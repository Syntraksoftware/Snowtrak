-- Run this in the Supabase SQL editor after 014 and 015. Additive: a new
-- function plus a create-or-replace of an existing one whose signature
-- does not change.

begin;

-- Approving is a delete and an insert, and they must not be separable: a
-- crash between them either drops the request or duplicates the edge.
-- Doing it here also makes it one round trip to a database ~440ms away
-- instead of two.
--
-- The insert fires the existing follows_apply_counts trigger, so the
-- stored counts stay correct with no change to the trigger. That is the
-- payoff for keeping pending requests out of `follows`.
create or replace function public.approve_follow_request(
  target uuid, requester uuid
) returns boolean
language plpgsql
as $$
declare moved boolean;
begin
  delete from follow_requests
   where target_id = target and requester_id = requester
  returning true into moved;

  if moved is null then
    return false;
  end if;

  insert into follows (follower_id, followee_id)
  values (requester, target)
  on conflict do nothing;

  return true;
end;
$$;

-- Same signature as 012, two more keys. The follow button has three states
-- now and they all come out of the one call the profile header already
-- makes.
create or replace function public.follow_stats(target uuid, viewer uuid)
returns json
language sql
stable
as $$
  select json_build_object(
    'follower_count',
      coalesce((select follower_count from follow_counts where user_id = target), 0),
    'following_count',
      coalesce((select following_count from follow_counts where user_id = target), 0),
    'is_following',
      (viewer is not null and exists (
        select 1 from follows where follower_id = viewer and followee_id = target
      )),
    'is_followed_by',
      (viewer is not null and exists (
        select 1 from follows where follower_id = target and followee_id = viewer
      )),
    'is_private',
      coalesce((select is_private from user_info where id = target), false),
    'has_requested',
      (viewer is not null and exists (
        select 1 from follow_requests where requester_id = viewer and target_id = target
      ))
  );
$$;

commit;
