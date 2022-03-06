from typing import ClassVar, cast

from pydantic import BaseModel

from core.elasticsearch.content_type.index import Index


class ContentType(BaseModel):
    id: str

    content_type: ClassVar[str | None] = None
    abstract: ClassVar[bool] = True

    def __init_subclass__(cls, *super_classes, content_type: str = None, abstract: bool = False):
        if not content_type and not abstract:
            raise ValueError("Must set the content type name when defining a new content type.")
        if content_type and ("-" in content_type or "." in content_type):
            raise ValueError("The content type name may not include characters '.' or '-'.")
        cls.content_type = content_type
        cls.abstract = abstract

    @classmethod
    def index(cls, language: str) -> Index:
        assert not cls.abstract
        return Index(cast(str, cls.content_type), language)
