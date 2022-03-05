from core.elasticsearch.content_type.base import ContentType


class User(ContentType, content_type="users"):
    username: str
