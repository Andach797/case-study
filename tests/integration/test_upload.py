from pathlib import Path

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_upload_happy(tmp_path: Path):
    csv = tmp_path / "sample.csv"
    csv.write_text("id,name,price\n1,foo,9.99\n")

    with csv.open("rb") as f:
        r = client.post(
            "/upload", files={"file": ("sample.csv", f, "text/csv")}
        )
    assert r.status_code == 200
    assert "sample.csv" in r.text
