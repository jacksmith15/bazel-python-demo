from functools import cache

from elasticsearch import AsyncElasticsearch

from core.elasticsearch.configuration import get_settings


@cache
def elasticsearch_client(timeout: float | None = None) -> AsyncElasticsearch:
    client = AsyncElasticsearch(
        get_settings().elasticsearch_hosts,
    )
    del timeout  # TODO: use this
    return client
