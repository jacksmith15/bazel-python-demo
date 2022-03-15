import pytest
from fastapi.testclient import TestClient

from users.content_type import User

LANGUAGE = "en"


class TestRetrieveUsers:
    @staticmethod
    @pytest.fixture(scope="class", autouse=True)
    async def load_users():
        index = User.index(LANGUAGE)
        await index.create_new_index(assign_aliases=True)
        users = [
            User(id=101, username="Caesar", language=LANGUAGE),
            User(id=102, username="Augustus", language=LANGUAGE),
        ]
        for user in users:
            await user.save()
        await index.refresh()

    @staticmethod
    def should_find_users_by_username(client: TestClient):
        response = client.get("/users", params={"language": LANGUAGE, "query": "caesar"})
        assert response.status_code == 200, response.text
        body = response.json()
        # TODO:
        # assert body == {"result": [{"id": 101, "username": "Caesar", "language": LANGUAGE}]}
        assert body == {"result": [{"id": "101", "username": "Caesar", "language": LANGUAGE}]}
