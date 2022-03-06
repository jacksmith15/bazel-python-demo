from typing import Generic, TypeVar

from pydantic.generics import GenericModel

ResultItem = TypeVar("ResultItem")


class ListResult(GenericModel, Generic[ResultItem]):
    result: list[ResultItem]
