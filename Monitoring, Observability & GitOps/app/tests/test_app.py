import json
import pytest
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_root_endpoint(client):
    response = client.get("/")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["status"] == "healthy"
    assert data["service"] == "telemetry-demo"
    assert "timestamp" in data


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["status"] == "UP"


def test_simulate_load_endpoint(client):
    response = client.get("/simulate-load")
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["status"] == "completed"
    assert data["iterations"] == 500_000


def test_metrics_endpoint(client):
    response = client.get("/metrics")
    assert response.status_code == 200
    content = response.data.decode("utf-8")
    assert "http_requests_total" in content
    assert "system_cpu_usage_percent" in content
    assert "system_memory_usage_bytes" in content


def test_metrics_increments_after_requests(client):
    client.get("/")
    client.get("/simulate-load")
    response = client.get("/metrics")
    assert response.status_code == 200
    content = response.data.decode("utf-8")
    assert 'endpoint="/"' in content
    assert 'endpoint="/simulate-load"' in content
