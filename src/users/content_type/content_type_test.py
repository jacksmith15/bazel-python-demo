from users.content_type import User


class TestUser:
    @staticmethod
    def should_parse_user():
        assert User(**{"id": 101, "username": "whoami"}).username == "whoami"
