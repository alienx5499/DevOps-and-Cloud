import time
from flask import Flask, jsonify, Response
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Prometheus Metrics
HTTP_REQUESTS_TOTAL = Counter(
    "http_requests_total",
    "Total HTTP request count",
    ["endpoint", "method", "status"]
)
SYSTEM_CPU_USAGE = Gauge(
    "system_cpu_usage_percent",
    "Current host/container CPU utilization percentage"
)
SYSTEM_MEMORY_USAGE = Gauge(
    "system_memory_usage_bytes",
    "Current host/container memory consumption in bytes"
)

# Initialize baseline gauge values
SYSTEM_CPU_USAGE.set(14.8)
SYSTEM_MEMORY_USAGE.set(345000000.0)


@app.route("/", methods=["GET"])
def root():
    HTTP_REQUESTS_TOTAL.labels(endpoint="/", method="GET", status="200").inc()
    return jsonify({
        "status": "healthy",
        "service": "telemetry-demo",
        "timestamp": int(time.time())
    }), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "UP"}), 200


@app.route("/simulate-load", methods=["GET"])
def simulate_load():
    HTTP_REQUESTS_TOTAL.labels(endpoint="/simulate-load", method="GET", status="200").inc()
    val = 0
    iterations = 500_000
    for i in range(iterations):
        val = (val + (i * i)) % 100
    return jsonify({
        "status": "completed",
        "calculated": val,
        "iterations": iterations
    }), 200


@app.route("/metrics", methods=["GET"])
def metrics():
    SYSTEM_CPU_USAGE.set(14.8)
    SYSTEM_MEMORY_USAGE.set(345000000.0)
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    print("Observability Telemetry Service listening on http://0.0.0.0:8000")
    app.run(host="0.0.0.0", port=8000)
