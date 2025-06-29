import io
import logging
from csv import reader
from datetime import datetime
from pathlib import Path
from typing import List

import boto3
import structlog
from botocore.exceptions import ClientError
from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.responses import HTMLResponse, PlainTextResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from settings import UPLOAD_DIR, settings
from starlette.middleware.base import BaseHTTPMiddleware

logging.basicConfig(level=settings.log_level, format="%(message)s")
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.stdlib.LoggerFactory(),
)
log = structlog.get_logger()

s3 = boto3.client("s3", region_name=settings.aws_region)
try:
    arn = boto3.client("sts").get_caller_identity()["Arn"]
    log.info("aws_identity", arn=arn)
except ClientError:
    log.warning("sts_failed")

app = FastAPI(title="CSV Processor")


class MaxSizeMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, limit_mb: int):
        super().__init__(app)
        self.max_bytes = limit_mb * 1024 * 1024

    async def dispatch(self, request, call_next):
        size = int(request.headers.get("content-length", 0))
        if size > self.max_bytes:
            return PlainTextResponse("file too large", status_code=413)
        return await call_next(request)


app.add_middleware(
    MaxSizeMiddleware,
    limit_mb=settings.max_upload_mb,
)

templates = Jinja2Templates(directory=str(Path(__file__).parent / "templates"))
app.mount(
    "/static",
    StaticFiles(directory=str(Path(__file__).parent / "static")),
    name="static",
)


def parse_csv(path: Path) -> List[List[str]]:
    rows: List[List[str]] = []
    with path.open("r", encoding="utf-8", errors="ignore") as f:
        for idx, row in enumerate(reader(f)):
            if not row or not any(cell.strip() for cell in row):
                continue
            if idx == 0 and len(row) != 3:
                raise ValueError("header must contain 3 columns")
            rows.append([c.strip() for c in row])
    if not rows:
        raise ValueError("CSV contained no data")
    return rows


@app.get(
    "/",
    response_class=HTMLResponse,
)
def index(request: Request) -> HTMLResponse:
    files = sorted(
        UPLOAD_DIR.glob("*.csv"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return templates.TemplateResponse(
        "upload.html",
        {
            "request": request,
            "files": [p.name for p in files],
        },
    )


@app.post(
    "/upload",
    response_class=HTMLResponse,
)
async def upload_csv(
    request: Request,
    file: UploadFile = File(...),
) -> HTMLResponse:
    log.info("upload_start", filename=file.filename)
    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(400, "only CSV files are allowed")

    ts = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    filename = f"{ts}-{Path(file.filename).name}"
    dest = UPLOAD_DIR / filename

    try:
        content = await file.read()

        dest.write_bytes(content)
        log.info("saved_local", path=str(dest))

        if settings.csv_bucket:
            buf = io.BytesIO(content)
            log.info(
                "s3_stream_begin",
                bucket=settings.csv_bucket,
                key=filename,
            )
            s3.upload_fileobj(buf, settings.csv_bucket, filename)
            log.info("s3_stream_done")

        rows = parse_csv(dest)
        log.info("parsed_rows", count=len(rows))

    except Exception as exc:
        log.error("processing_failed", error=str(exc))
        dest.unlink(missing_ok=True)
        raise HTTPException(
            500,
            f"processing failed: {exc}",
        ) from exc

    return templates.TemplateResponse(
        "show.html",
        {
            "request": request,
            "rows": rows,
            "filename": filename,
        },
    )


@app.get(
    "/files/{filename}",
    response_class=HTMLResponse,
)
def show_file(
    request: Request,
    filename: str,
) -> HTMLResponse:
    if filename != Path(filename).name:
        raise HTTPException(400, "bad filename")

    target = UPLOAD_DIR / filename
    if not target.exists():
        raise HTTPException(404, "not found")

    rows = parse_csv(target)
    log.info(
        "display_file",
        filename=filename,
        rows=len(rows),
    )
    return templates.TemplateResponse(
        "show.html",
        {
            "request": request,
            "rows": rows,
            "filename": filename,
        },
    )
