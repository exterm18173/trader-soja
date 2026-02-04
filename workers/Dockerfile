FROM python:3.12-slim

WORKDIR /workers

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY workers/requirements.txt /workers/requirements.txt
RUN pip install --no-cache-dir -r /workers/requirements.txt

COPY workers /workers
