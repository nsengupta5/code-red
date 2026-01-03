FROM gcr.io/dataflow-templates-base/python3-template-launcher-base

WORKDIR /template

# Copy requirements first (better caching)
COPY requirements.txt constraints.txt ./

RUN pip install \
    --no-cache-dir \
    -r requirements.txt \
    --constraint constraints.txt


# Copy your pipeline code
COPY src/ ./src/

# REQUIRED: tell Dataflow where the pipeline entrypoint is
ENV FLEX_TEMPLATE_PYTHON_PY_FILE=src/main.py
ENV FLEX_TEMPLATE_PYTHON_REQUIREMENTS_FILE=requirements.txt
