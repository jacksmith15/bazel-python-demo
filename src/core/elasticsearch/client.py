from functools import cache

from elasticsearch import AsyncElasticsearch
from core.elasticsearch.configuration import get_settings

@cache
def elasticsearch_client(timeout: float | None) -> AsyncElasticsearch:
    client = AsyncElasticsearch(
        get_settings().elasticsearch_hosts,
    )
    return client
