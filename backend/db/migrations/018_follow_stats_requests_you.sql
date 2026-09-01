-- Run this in the Supabase SQL editor after 017. Additive: a create-or-replace
-- of one function whose signature does not change, and one more key in the
-- JSON it returns. Old code ignores the new key, so this is safe on its own
-- and safe to leave in place if the deploy is rolled back.

begin;

-- Same signature as 017, one more key.
--
-- `has_requested` is the outgoing direction -- the viewer is waiting on this
-- account. `requests_you` is the incoming one: this account is waiting on the
-- viewer. Without it a profile cannot offer Approve and Deny, because it has
-- no way to know a request is pending without pulling the whole request list
-- on every profile open.
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
      )),
    'requests_you',
      (viewer is not null and exists (
        select 1 from follow_requests where requester_id = target and target_id = viewer
      ))
  );
$$;

commit;
