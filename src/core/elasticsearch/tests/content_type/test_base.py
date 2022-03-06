import pytest

from core.elasticsearch.content_type.base import ContentType

# Checking test PYTHONPATH configuration:
from core.elasticsearch.tests.fixtures import FOO

del FOO


class TestContentType:
    @staticmethod
    def should_raise_if_content_type_missing():
        with pytest.raises(ValueError):

            class _MyContentType(ContentType):
                pass
