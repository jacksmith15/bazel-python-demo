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

    @staticmethod
    def should_allow_subclass_if_content_type_is_set():
        class _MyContentType(ContentType, content_type="my_content_type"):
            pass

        assert _MyContentType.content_type == "my_content_type"

    @staticmethod
    def should_allow_abstract_subclass():
        class _MyContentType(ContentType, abstract=True):
            pass

    @staticmethod
    def should_inherit_content_type():
        class _Super(ContentType, content_type="super"):
            pass

        class _Sub(_Super):
            pass

        assert _Sub.content_type == "super"
