from fastapi import FastAPI, File, UploadFile, Request, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from csv import reader
from pathlib import Path
from datetime import datetime
import shutil
from typing import List
# TODO: Order imports at some point lol. Also black formatter maybe?
import boto3
from app.settings import CSV_BUCKET

app = FastAPI(title="CSV Processor")

BASE_DIR = Path(__file__).parent.resolve()
UPLOAD_DIR = BASE_DIR.parent / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))
app.mount(
    "/static",
    StaticFiles(directory=str(Path(__file__).parent / "static")),
    name="static",
)


def parse_csv(path: Path) -> List[List[str]]:
    """Return list of non-empty CSV rows."""
    rows: List[List[str]] = []
    with path.open("r", encoding="utf-8", errors="ignore") as f:
        csv_reader = reader(f)
        for row in csv_reader:
            if row and any(cell.strip() for cell in row):
                rows.append([cell.strip() for cell in row])
    if not rows:
        raise ValueError("CSV contained no data")
    return rows


@app.get("/", response_class=HTMLResponse)
def index(request: Request) -> HTMLResponse:
    files = sorted(
        UPLOAD_DIR.glob("*.csv"), key=lambda p: p.stat().st_mtime, reverse=True
    )
    return templates.TemplateResponse(
        "upload.html", {"request": request, "files": [p.name for p in files]}
    )


@app.post("/upload", response_class=HTMLResponse)
async def upload_csv(request: Request, file: UploadFile = File(...)) -> HTMLResponse:
    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(400, "Only CSV files are allowed")

    safe_name = Path(file.filename).name
    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    dest = UPLOAD_DIR / f"{ts}-{safe_name}"
    with dest.open("wb") as buf:
        shutil.copyfileobj(file.file, buf)

    try:
        rows = parse_csv(dest)
    except Exception as exc:
        dest.unlink(missing_ok=True)
        raise HTTPException(400, f"Failed to parse CSV: {exc}") from exc

    # Upload to S3 if bucket is configured
    if CSV_BUCKET:
        try:
            boto3.client("s3").upload_file(str(dest), CSV_BUCKET, dest.name)
        except Exception as exc:
            # TODO: testing; don't break local preview if S3 fails
            raise HTTPException(500, f"S3 upload failed: {exc}") from exc

    return templates.TemplateResponse(
        "show.html",
        {"request": request, "rows": rows, "filename": dest.name},
    )


@app.get("/files/{filename}", response_class=HTMLResponse)
def show_file(request: Request, filename: str) -> HTMLResponse:
    # prevent path traversal
    if filename != Path(filename).name:
        raise HTTPException(400, "Invalid filename")
    target = UPLOAD_DIR / filename
    if not target.exists():
        raise HTTPException(404, "File not found")

    rows = parse_csv(target)
    return templates.TemplateResponse(
        "show.html",
        {"request": request, "rows": rows, "filename": filename},
    )
