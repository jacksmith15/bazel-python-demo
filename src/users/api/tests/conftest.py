import asyncio
import json
import os
from collections.abc import Iterator
from pathlib import Path

import pytest
import requests
from fastapi.testclient import TestClient
from pytest_docker.plugin import Services

from core.elasticsearch.configuration import get_settings
from users.api import api


@pytest.fixture(scope="session")
def event_loop():
    """Make the event loop last for the whole session.

    Overrides pytest-asyncio implementation to make it session wide so that the event_loop is not
    closed all the time.
    """
    loop = asyncio.get_event_loop_policy().new_event_loop()
    try:
        yield loop
    finally:
        loop.close()


@pytest.fixture(scope="session")
def docker_compose_file() -> str:
    return str(Path(__file__).parent / "docker-compose.yml")


@pytest.fixture(scope="session")
def elasticsearch_hosts(docker_services: Services, docker_ip: str) -> str:
    port = docker_services.port_for("elasticsearch", 9200)
    url = f"http://{docker_ip}:{port}"
    docker_services.wait_until_responsive(timeout=90.0, pause=1, check=lambda: is_responsive(url))
    return url


@pytest.fixture(scope="session", autouse=True)
def override_env(elasticsearch_hosts: str):
    existing = os.getenv("ELASTICSEARCH_HOSTS")
    try:
        os.environ["ELASTICSEARCH_HOSTS"] = json.dumps([elasticsearch_hosts])
        get_settings.cache_clear()
        yield
    finally:
        if existing is not None:
            os.environ["ELASTICSEARCH_HOSTS"] = existing
        else:
            del os.environ["ELASTICSEARCH_HOSTS"]


@pytest.fixture(scope="session")
def client(event_loop) -> Iterator[TestClient]:
    del event_loop
    with TestClient(api) as client:
        yield client


def is_responsive(url: str) -> bool:
    try:
        response = requests.get(url)
        return response.status_code == 200
    except requests.ConnectionError:
        return False
