FROM python:3.12-slim

LABEL org.opencontainers.image.source="https://github.com/leandrosanttos007/lab-teste1"
LABEL org.opencontainers.image.description="Lab de CI/CD com GitOps: app Python (Flask) + pipeline que publica a imagem e atualiza o deployment"

WORKDIR /app

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

RUN addgroup --system app && adduser --system --ingroup app app

COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

USER app
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health', timeout=2)"

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
