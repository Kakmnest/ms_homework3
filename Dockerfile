FROM python:3.13-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

RUN groupadd --gid 1000 counter \
    && useradd --uid 1000 --gid counter --no-create-home counter \
    && install -d -o counter -g counter /data

ENV PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    GREETING="Hello, Docker!" \
    STORAGE=sqlite \
    DATA_FILE=/data/counter.db

USER counter
EXPOSE 8000

CMD ["python", "app.py"]
