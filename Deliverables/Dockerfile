FROM python:3.10-slim

WORKDIR /app

COPY analytics/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY analytics/ .

ENV APP_PORT=5153

EXPOSE 5153

ENTRYPOINT ["python", "app.py"]

