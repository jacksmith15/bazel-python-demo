from functools import wraps
from typing import Any, Callable, Coroutine, Dict, List, Optional, Sequence, Type, Union

from fastapi import FastAPI

from core.api.middleware import DEFAULT_MIDDLEWARE


@wraps(FastAPI)
def create_api(*args, **kwargs):
    api = FastAPI(*args, **kwargs)
    for middleware in DEFAULT_MIDDLEWARE:
        api.middleware("http")(middleware)
    return api
