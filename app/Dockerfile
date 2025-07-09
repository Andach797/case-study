# build
FROM python:3.12-slim AS builder
WORKDIR /tmp/build

COPY requirements.txt .
RUN pip install --upgrade pip \
 && pip wheel --no-cache-dir -r requirements.txt

FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1

RUN addgroup --system app \
 && adduser --system --ingroup app --home /home/app app

WORKDIR /app

# bring in wheels & requirements
COPY --from=builder /tmp/build/requirements.txt /app/
COPY --from=builder /tmp/build/*.whl /app/wheels/
COPY --chown=app:app . /app

RUN chown -R app:app /app

USER app
ENV PATH="/home/app/.local/bin:${PATH}"

# install from local wheels as non-root
RUN pip install --no-cache-dir --no-index \
    --find-links=/app/wheels \
    -r /app/requirements.txt --user

ENV STATIC_DIR=/static
EXPOSE 8000

CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "--workers", "4", "--bind", "0.0.0.0:8000", "main:app"]
