FROM python:3.11-slim

# Prevent Python from buffering logs (important for Dataflow / debugging)
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install deps first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/

# Default command (can be overridden by Dataflow / Composer)
CMD ["python", "src/main.py"]
