import os
from datetime import datetime, timezone

from flask import Flask, jsonify, render_template

app = Flask(__name__)

APP_NAME = "lab-teste1"
APP_VERSION = os.environ.get("APP_VERSION", "dev")


def horario_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


@app.get("/")
def index():
    return render_template(
        "index.html",
        app_name=APP_NAME,
        version=APP_VERSION,
        horario=horario_utc(),
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/api/info")
def info():
    return jsonify(
        app=APP_NAME,
        version=APP_VERSION,
        horario=horario_utc(),
        status="ok",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
