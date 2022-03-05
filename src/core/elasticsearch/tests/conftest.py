import json
import os

import pytest


@pytest.fixture(scope="session", autouse=True)
def _set_environment():
    existing = os.getenv("ELASTICSEARCH_HOSTS")
    try:
        os.environ["ELASTICSEARCH_HOSTS"] = json.dumps(["http://example.com"])
        yield
    finally:
        if existing is not None:
            os.environ["ELASTICSEARCH_HOSTS"] = existing
        else:
            del os.environ["ELASTICSEARCH_HOSTS"]
