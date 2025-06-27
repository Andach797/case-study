import os
from pathlib import Path

BASE_DIR = Path(__file__).parent
UPLOAD_DIR = BASE_DIR.parent / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)

# TODO: Read bucket name from env var fallback to local usage for now
CSV_BUCKET = os.getenv("CSV_BUCKET")