import pytest
from fastapi import status

import app.main as main_mod


def _csv(content: str) -> bytes:
    return content.encode("utf-8")


def test_parse_csv_happy(tmp_path):
    sample = tmp_path / "good.csv"
    sample.write_text("a,b,c\n1,2,3\n")
    rows = main_mod.parse_csv(sample)
    assert rows == [["a", "b", "c"], ["1", "2", "3"]]


def test_parse_csv_bad_header(tmp_path):
    bad = tmp_path / "bad.csv"
    bad.write_text("a,b\n1,2\n")
    with pytest.raises(ValueError, match="header must contain 3 columns"):
        main_mod.parse_csv(bad)


def test_parse_csv_empty(tmp_path):
    empty = tmp_path / "empty.csv"
    empty.write_text("")
    with pytest.raises(ValueError, match="CSV contained no data"):
        main_mod.parse_csv(empty)


def test_index_lists_files(client, tmp_path):
    uploads = client.app.state.UPLOAD_DIR
    (uploads / "x.csv").write_text("a,b,c\n")
    resp = client.get("/")
    assert resp.status_code == status.HTTP_200_OK
    assert "x.csv" in resp.text


def test_upload_csv_rejects_non_csv(client):
    resp = client.post("/upload", files={"file": ("file.txt", b"irrelevant")})
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_upload_csv_success(client):
    data = _csv("a,b,c\n1,2,3\n")
    resp = client.post("/upload", files={"file": ("sample.csv", data)})
    assert resp.status_code == status.HTTP_200_OK
    assert "sample.csv" in resp.text
    assert "<table" in resp.text


def test_show_file_bad_filename(client):
    resp = client.get("/files/../../../passwd.csv")
    # Router rejects path first, so 404 is fine
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_show_file_not_found(client):
    resp = client.get("/files/missing.csv")
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_show_file_success(client):
    # Upload a CSV so it exists
    client.post("/upload", files={"file": ("x.csv", _csv("a,b,c\n1,2,3\n"))})

    # pick the timestamped filename that was actually written
    saved = next(client.app.state.UPLOAD_DIR.glob("*x.csv")).name
    resp = client.get(f"/files/{saved}")
    assert resp.status_code == status.HTTP_200_OK
    assert "1" in resp.text and "2" in resp.text and "3" in resp.text
