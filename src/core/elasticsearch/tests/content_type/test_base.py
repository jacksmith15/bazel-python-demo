import pytest

from core.elasticsearch.content_type.base import ContentType
from tests.fixtures import FOO
from content_type.index import Index

class TestContentType:
    @staticmethod
    def should_raise_if_content_type_missing():
        with pytest.raises(ValueError):
            class MyContentType(ContentType):
                pass
