import logging
from functools import cache

from pydantic import AnyHttpUrl, BaseSettings, Field


class ElasticsearchSettings(BaseSettings):
    elasticsearch_hosts: list[AnyHttpUrl] = Field(
        description="Value used for `hosts` argument of `elasticsearch.client.Elasticsearch.__init__`. "
        "Exposed via `parsed_elasticsearch_hosts`."
    )
    elasticsearch_log_level: str = Field(default="WARNING", description="Level for Elasticsearch log messages.")

    elasticsearch_scope: str = Field(
        default="gs2",
        description="The scope used to namespace indices in Elasticsearch. Useful for multi-tenant clusters.",
    )

    @property
    def parsed_elasticsearch_hosts(self):
        return list(map(str, self.elasticsearch_hosts))


@cache
def get_settings():
    settings = ElasticsearchSettings()
    logging.getLogger("elasticsearch").setLevel(settings.elasticsearch_log_level)
    return settings
