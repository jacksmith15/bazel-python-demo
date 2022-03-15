from typing import ClassVar, cast

from elasticsearch import AsyncElasticsearch
from pydantic import BaseModel

from core.elasticsearch.client import elasticsearch_client
from core.elasticsearch.content_type.index import Index


class ContentType(BaseModel):
    id: str
    language: str

    content_type: ClassVar[str | None] = None
    abstract: ClassVar[bool] = True

    def __init_subclass__(cls, content_type: str = None, abstract: bool = False):
        content_type = content_type or _inherited_content_type(cls)
        if not content_type and not abstract:
            raise ValueError("Must set the content type name when defining a new content type.")
        if content_type and ("-" in content_type or "." in content_type):
            raise ValueError("The content type name may not include characters '.' or '-'.")
        cls.content_type = content_type
        cls.abstract = abstract
        super().__init_subclass__()

    @classmethod
    def index(cls, language: str) -> Index:
        assert not cls.abstract
        return Index(cast(str, cls.content_type), language)

    async def save(self, client: AsyncElasticsearch = None) -> None:
        index = self.__class__.index(self.language)
        client = client or elasticsearch_client()
        await client.index(
            index=index.write_alias.name,
            document=self.dict(),
        )


def _inherited_content_type(cls) -> str | None:
    for super_class in cls.mro():
        if issubclass(super_class, ContentType):
            content_type = getattr(super_class, "content_type", None)
            if content_type:
                return content_type
    return None
