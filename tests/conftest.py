import importlib
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import Mock

import boto3  # noqa: E402
import pytest
from fastapi.testclient import TestClient

_fake_sts = Mock()
_fake_sts.get_caller_identity.return_value = {"Arn": "arn:test:local"}


def _fake_client(service_name, *_, **__):
    if service_name == "sts":
        return _fake_sts

    if service_name == "s3":

        class _FakeS3:
            def upload_fileobj(self, *__, **___):
                return None

        return _FakeS3()

    return Mock()


boto3.client = _fake_client  # type: ignore[attr-defined]


sys.modules.setdefault("settings", importlib.import_module("app.settings"))


import app.main as main_mod  # noqa: E402


@pytest.fixture(autouse=True)
def _tmp_upload_dir(monkeypatch):
    """Each test gets an isolated uploads/ directory."""
    with TemporaryDirectory() as tmp:
        uploads = Path(tmp)
        monkeypatch.setattr(main_mod, "UPLOAD_DIR", uploads)
        main_mod.app.state.UPLOAD_DIR = uploads
        uploads.mkdir(parents=True, exist_ok=True)
        yield uploads


@pytest.fixture
def client():
    return TestClient(main_mod.app)
