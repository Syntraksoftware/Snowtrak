"""The display ladder.

One rule, four rungs, and the `@` belongs to the first rung only. This is
the Python half; `CommunityAuthorMapper.authorDisplayName` is the Dart half
and is tested against the same four cases.
"""

from shared.display_name import UNKNOWN_PLAYER, display_name


def test_a_chosen_username_wins_and_carries_the_at_sign():
    assert (
        display_name(
            username="snowking",
            first_name="Matthew",
            last_name="Ng",
            email="matthew@example.com",
        )
        == "@snowking"
    )


def test_without_a_username_the_name_shows_with_no_at_sign():
    # "@Matthew Ng" would be wrong: the @ marks a handle, not a person.
    assert (
        display_name(
            username=None,
            first_name="Matthew",
            last_name="Ng",
            email="matthew@example.com",
        )
        == "Matthew Ng"
    )


def test_with_neither_it_falls_back_to_the_email_handle():
    assert (
        display_name(
            username=None,
            first_name=None,
            last_name=None,
            email="skier@example.com",
        )
        == "skier"
    )


def test_a_deleted_author_outranks_everything_it_still_carries():
    # A cached row can still hold the old name. None of it may be shown.
    assert (
        display_name(
            username="snowking",
            first_name="Matthew",
            last_name="Ng",
            email="matthew@example.com",
            deleted=True,
        )
        == UNKNOWN_PLAYER
    )


def test_blank_strings_count_as_absent():
    # Supabase returns "" rather than null for a cleared text field often
    # enough that treating them differently is a bug waiting to happen.
    assert display_name(username="  ", first_name="", last_name="", email="a@b.co") == "a"


def test_nothing_at_all_still_returns_something_printable():
    assert (
        display_name(username=None, first_name=None, last_name=None, email=None) == UNKNOWN_PLAYER
    )
