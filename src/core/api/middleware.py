import time
from collections.abc import Awaitable, Callable

from fastapi import Request, Response

from core.logging import logger


async def logging_middleware(request: Request, call_next: Callable[[Request], Awaitable[Response]]):
    start = time.monotonic()
    context = {"path": request.url.path, "query": str(request.query_params)}
    try:
        response = await call_next(request)
    except Exception as exc:
        logger.info(
            "HTTP response",
            http=context | {"status": 500, "duration": time.monotonic() - start},
            error={"message": str(exc)},
        )
        raise exc from None
    logger.info("HTTP response", http=context | {"status": response.status_code, "duration": time.monotonic() - start})
    return response


DEFAULT_MIDDLEWARE = [logging_middleware]
