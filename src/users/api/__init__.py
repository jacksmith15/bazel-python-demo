from fastapi import HTTPException, Query

from core.api import create_api
from core.api.models import ListResult
from core.elasticsearch.client import elasticsearch_client
from users.content_type import User

api = create_api(title="users-api")


@api.get("/users", response_model=ListResult[User])
async def fetch_users(language: str = Query(...), query: str = Query(...)):
    client = elasticsearch_client()
    index = User.index(language).read_alias
    if not await index.exists():
        raise HTTPException(status_code=404, detail=f"Language {language!r} not found.")
    response = await client.search(index=index.name, body={"query": {"match": {"username": query}}})
    result = [User(**hit["_source"]) for hit in response["hits"]["hits"]]
    return {"result": result}
