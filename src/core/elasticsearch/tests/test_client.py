from core.elasticsearch.client import elasticsearch_client


class TestElasticsearchClient:
    @staticmethod
    def should_get_client():
        _ = elasticsearch_client()
