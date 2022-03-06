import json
import os
import sys
from dataclasses import dataclass
from enum import Enum, auto
from typing import TYPE_CHECKING, Any, TextIO

import loguru

if TYPE_CHECKING:
    from loguru import Logger, Message, Record


class LogLevel(Enum):
    # pylint: disable=no-self-argument
    def _generate_next_value_(name: str, *args: Any) -> str:  # type: ignore[misc,override]
        del args
        return name

    # pylint: enable=no-self-argument

    DEBUG = auto()
    INFO = auto()
    WARNING = auto()
    ERROR = auto()
    CRITICAL = auto()


def setup_logger(
    log_level: str = "INFO",
    sink: TextIO = sys.stdout,
) -> "Logger":
    """Configure the logger."""
    LogLevel(log_level)  # Validate

    loguru.logger.configure(handlers=[])  # removes all pre-existing handlers

    handler = JSONHandler(sink)
    loguru.logger.add(handler, format="<level>{message}</level>", serialize=False, level=log_level)

    return loguru.logger


@dataclass
class JSONHandler:
    file_obj: TextIO

    def write(self, message: "Message") -> None:
        """Write the structured log entry to the output stream."""
        record: "Record" = message.record
        struct = {
            "level": record["level"].name,
            "time": record["time"].isoformat(),
            "message": record["message"],
            **record["extra"],
        }
        self.file_obj.write(f"{json.dumps(struct)}{os.linesep}")

    def flush(self) -> None:
        """Flush the output stream."""
        self.file_obj.flush()
