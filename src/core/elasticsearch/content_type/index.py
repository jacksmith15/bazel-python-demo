from __future__ import annotations

import asyncio
from abc import ABC, abstractmethod
from datetime import datetime
from enum import Enum
from functools import cached_property
from typing import List, Optional

import elasticsearch
from elasticsearch import AsyncElasticsearch
from elasticsearch._async.client.indices import IndicesClient
from elasticsearch.exceptions import NotFoundError

from core.elasticsearch.client import elasticsearch_client
from core.elasticsearch.configuration import get_settings


class Alias:
    """Alias for an index.

    Helpers to inspect and assign indexes. Used by `Index` and should not be instantiated directly.
    """

    def __init__(
        self,
        index: Index,
        name: str,
        write_alias: bool = False,
    ):
        self._index = index
        self._write_alias = write_alias
        self.name = name

    def __repr__(self) -> str:
        return f"Alias({repr(self.name)})"

    def __str__(self) -> str:
        return self.name

    async def exists(self, index_name: str = None) -> bool:
        """
        Returns True if the alias exists; otherwise (e.g., it's an index or is missing), False.

        If `index` is also specified, then `alias` must exist and it must point to `index`.
        Retries a few times to get around an ES bug which 404s on index name/alias listing operations.
        """
        resp = await elasticsearch_client().cat.aliases(name=self.name, params={"format": "json", "h": "index"})
        assert isinstance(resp, list), "Expected result of cat/aliases request to be a list"
        if not resp or (index_name and index_name not in [x["index"] for x in resp]):
            return False
        return True

    async def wait_exists(self, timeout: int | float = 60.0) -> bool:
        """Wait for an index to exist.

        Useful for non-leader faust agents, to wait for the leader to create the alias.
        """
        waited_duration = 0
        wait_duration = 1
        while waited_duration < timeout:
            if await self.exists():
                return True
            await asyncio.sleep(wait_duration)
            waited_duration += wait_duration
        raise RuntimeError(f"Waited for alias {repr(self.name)} to appear, but it never did.")

    async def assign(self, index_name: str) -> None:
        """
        Update alias `alias` so it points to a single destination index `index`.

        Any previous index(es) that `alias` pointed to will be removed.
        """
        add_action: dict = {"index": index_name, "alias": self.name}
        if self._write_alias:
            add_action["is_write_index"] = True
        actions = [
            {"remove": {"index": "*", "alias": self.name}},
            {"add": add_action},
        ]
        await elasticsearch_client().indices.update_aliases(body={"actions": actions})

    async def remove(self) -> None:
        await elasticsearch_client().indices.delete_alias(index=self._index.index_pattern, name=self.name)

    async def current_index(self) -> Optional[str]:
        try:
            return list((await elasticsearch_client().indices.get_alias(name=self.name)))[0]
        except IndexError:
            return None


class Index:
    """Abstract helper for ensuring consistent index and alias management between content types."""

    def __init__(self, content_type: str, language: str):
        self.content_type = content_type
        self.language = language

    def __repr__(self) -> str:
        return f"{type(self).__name__}({repr(self._base_name)})"

    @property
    def index_pattern(self):
        return f"{self._base_name}.v.*"

    @property
    def _base_name(self):
        config = get_settings()
        return f"{config.elasticsearch_scope}.{self.language}_{self.content_type}".lower()

    def _alias(self, alias_suffix: str, write_alias: bool = False):
        return Alias(self, f"{self._base_name}.{alias_suffix}", write_alias)

    @property
    def read_alias(self) -> Alias:
        return self._alias("read")

    @property
    def write_alias(self) -> Alias:
        return self._alias("write", write_alias=True)

    async def newest_index_name(self) -> str | None:
        """
        Retrieve indexes matching index_pattern and determine the newest one using index name datestamps.

        Returns:
            Name of most recent matching index, or None if none found.
        """
        try:
            return sorted(await self.matching_indices())[-1]
        except IndexError:
            return None

    async def matching_indices(self) -> List[str]:
        matches = await elasticsearch_client().indices.get(index=self.index_pattern)
        return list(matches.keys())

    async def create_new_index(self) -> str:
        """Creates a new index following the naming convention and returns its name.

        Convention is {scope}.{content_name}.{index_type_indicator}.{time_specifier}.
        Example:
            gs2.en_recipes_v3.v.20190711t095000z
        """
        timestamp = datetime.now().strftime("%Y%m%dt%H%M%Sz")
        index_name = f"{self._base_name}.v.{timestamp}"
        await elasticsearch_client().indices.create(index=index_name)
        return index_name
