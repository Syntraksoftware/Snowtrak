"""How a person is named on screen.

One rule, stated in
docs/superpowers/specs/2026-09-04-profiles-repair-design.md and implemented
here for every surface that sends a finished name. The community feed sends
raw fields instead and resolves the same rule in Dart; the two are tested
against the same cases.
"""

#: Shown for an author who is gone, or who has nothing to be named by.
UNKNOWN_PLAYER = "Skier"


def display_name(
    *,
    username: str | None,
    first_name: str | None,
    last_name: str | None,
    email: str | None,
    deleted: bool = False,
) -> str:
    """The name to show for one person.

    Args:
        username: The handle they chose, if any.
        first_name: Their given name.
        last_name: Their family name.
        email: Their address, used only for its handle.
        deleted: Whether the account is gone. Outranks everything else --
            a cached row can still carry the old name, and none of it may
            be shown.

    Returns:
        `@handle` when a username is set, their name when it is not, the
        email handle when there is neither, and `UNKNOWN_PLAYER` when there
        is nothing at all. The `@` marks a handle and never a person, so it
        appears on the first rung only.
    """
    if deleted:
        return UNKNOWN_PLAYER

    handle = (username or "").strip()
    if handle:
        return f"@{handle}"

    first = (first_name or "").strip()
    last = (last_name or "").strip()
    full = " ".join(part for part in (first, last) if part)
    if full:
        return full

    address = (email or "").strip()
    if "@" in address:
        return address.split("@")[0]

    return UNKNOWN_PLAYER
