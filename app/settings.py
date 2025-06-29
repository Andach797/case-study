from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

import json, os, logging, boto3

def _inject_secrets():
    arn = os.getenv("CONFIG_SECRET_ARN")
    if not arn:
        return
    region = os.getenv("AWS_DEFAULT_REGION", "eu-central-1")
    sm = boto3.client("secretsmanager", region_name=region)
    try:
        payload = sm.get_secret_value(SecretId=arn)["SecretString"]
        for k, v in json.loads(payload).items():
            os.environ.setdefault(k, str(v))
    except Exception as exc:
        logging.warning("secrets-manager-fetch-failed %s", exc)

_inject_secrets()

class Settings(BaseSettings):
    csv_bucket: str = Field("", env="CSV_BUCKET")
    aws_region: str = Field("eu-central-1", env="AWS_DEFAULT_REGION")
    max_upload_mb: int = Field(5, env="MAX_UPLOAD_MB")
    log_level: str = Field("INFO", env="LOG_LEVEL")

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=False
    )

settings = Settings()

BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
