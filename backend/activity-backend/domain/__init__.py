"""Pure domain rules for activity-backend.

Nothing under `domain/` imports a client, a config or a route. It is a
function of values that have already been read, which is what lets the rules
be tested without a network and changed without touching persistence.
"""
