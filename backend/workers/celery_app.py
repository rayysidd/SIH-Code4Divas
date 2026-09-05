import os
import socket
from urllib.parse import urlparse
from celery import Celery

REDIS_URL = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0")


def is_redis_available(timeout: float = 0.3) -> bool:
    """Fast non-blocking check to verify if Redis broker is reachable."""
    try:
        parsed = urlparse(REDIS_URL)
        host = parsed.hostname or "127.0.0.1"
        port = parsed.port or 6379
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except Exception:
        return False


celery_app = Celery(
    "labellens_workers",
    broker=REDIS_URL,
    backend=REDIS_URL,
    include=["workers.tasks.scan_task"]
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Kolkata",
    enable_utc=True,
    broker_connection_retry_on_startup=False,
    broker_connection_max_retries=1,
    result_backend_transport_options={
        "max_retries": 1,
        "interval_start": 0,
        "interval_step": 0.1,
        "interval_max": 0.2,
    },
)
