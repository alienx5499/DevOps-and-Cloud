# Python Calculator Application Dockerfile
FROM python:3.12-alpine

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

# Environment configurations
ENV PYTHONUNBUFFERED=1

# Run calculator application
CMD ["python", "app/calculator.py"]
