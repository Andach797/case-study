from pathlib import Path

UPLOAD_DIR: Path = Path(__file__).parent / ".." / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)
