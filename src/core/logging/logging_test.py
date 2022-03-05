import json
from io import StringIO

import pytest

from core.logging import logger, setup_logger


class TestLogging:
    @staticmethod
    @pytest.fixture(scope="class", autouse=True)
    def log_stream() -> StringIO:
        sink = StringIO()
        setup_logger("INFO", sink)
        return sink

    @staticmethod
    def should_log_in_json_format(log_stream: StringIO):
        logger.info("Hello", name="world")
        output = log_stream.getvalue().splitlines()
        assert len(output) == 1
        value = json.loads(output[0])
        value.pop("time")
        assert value == {
            "level": "INFO",
            "message": "Hello",
            "name": "world",
        }
