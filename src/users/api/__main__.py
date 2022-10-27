import uvicorn

from core.logging.configuration import setup_logger
from users.api import api


if __name__ == "__main__":
    setup_logger()
    uvicorn.run(api, host="0.0.0.0", port=8096, access_log=False)
