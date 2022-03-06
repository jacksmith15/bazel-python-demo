import json
from io import StringIO

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from core.api.api import create_api
from core.logging import setup_logger

api: FastAPI = create_api()


@api.get("/path")
def get():
    return {"status": "OK"}


class TestAPI:
    @staticmethod
    @pytest.fixture(scope="class", autouse=True)
    def log_stream() -> StringIO:
        sink = StringIO()
        setup_logger("INFO", sink)
        return sink

    @staticmethod
    @pytest.fixture(scope="class")
    def testclient(log_stream: StringIO):
        del log_stream
        return TestClient(api)

    @staticmethod
    def should_configures_middleware(testclient: TestClient, log_stream: StringIO):
        response = testclient.get("/path")
        assert response.status_code == 200
        output = log_stream.getvalue().splitlines()
        value = json.loads(output[-1])
        assert set(value) == {"level", "time", "http", "message"}
        value.pop("time")
        http = value.pop("http")
        assert value == {"level": "INFO", "message": "HTTP response"}

        http.pop("duration")
        assert http == {"path": "/path", "query": "", "status": 200}
