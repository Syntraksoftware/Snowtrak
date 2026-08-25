"""The secret-key guard in app.core.config."""

import pytest
from pydantic import ValidationError

from app.core.config import DEV_SECRET_KEY, Settings


@pytest.fixture(autouse=True)
def no_ambient_config(monkeypatch):
    """Ignore whatever the developer's shell happens to export."""
    for name in ("SECRET_KEY", "JWT_SECRET", "FASTAPI_ENV", "ENVIRONMENT"):
        monkeypatch.delenv(name, raising=False)


def test_dev_secret_is_rejected_on_a_deployed_stack():
    with pytest.raises(ValidationError):
        Settings(_env_file=None, FASTAPI_ENV="production")


def test_dev_secret_is_fine_on_a_laptop():
    assert Settings(_env_file=None).secret_key == DEV_SECRET_KEY


def test_jwt_secret_satisfies_secret_key():
    """The name the other three services use is accepted here too."""
    settings = Settings(_env_file=None, JWT_SECRET="shared-value", FASTAPI_ENV="production")
    assert settings.secret_key == "shared-value"
