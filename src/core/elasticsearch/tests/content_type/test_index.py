import pytest

from core.elasticsearch.content_type.base import Index


class TestIndex:
    @staticmethod
    @pytest.mark.parametrize(
        "language,content_type,write,expected",
        [
            ("en", "users", False, "gs2.en_users.read"),
            ("en", "users", True, "gs2.en_users.write"),
        ],
    )
    def should_produce_correct_aliases(language: str, content_type: str, write: bool, expected: str):
        index = Index(content_type, language)
        if write:
            assert index.write_alias.name == expected
        else:
            assert index.read_alias.name == expected
