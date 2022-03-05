from core.elasticsearch.content_type.base import ContentType


class Recipe(ContentType, content_type="recipes"):
    title: str
    author_id: str
    steps: list[str]
