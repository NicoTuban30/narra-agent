# This is an example Dockerfile that builds a minimal container for running LK Agents
# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.11.6
FROM python:${PYTHON_VERSION}-slim

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/appuser" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    appuser


# Install gcc and other build dependencies.
RUN apt-get update && \
    apt-get install -y \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

USER appuser

RUN mkdir -p /home/appuser/.cache
RUN chown -R appuser /home/appuser/.cache

WORKDIR /home/appuser

COPY requirements.txt .
RUN python -m pip install --user --no-cache-dir -r requirements.txt

COPY . .

# Accept build arguments for environment variables
ARG OPENAI_API_KEY
ARG BUBBLE_TRANSCRIPT_ENDPOINT
ARG BUBBLE_GET_TRANSCRIPT_ENDPOINT
ARG BUBBLE_STORY_ENDPOINT

# Set environment variables
ENV OPENAI_API_KEY=$OPENAI_API_KEY
ENV BUBBLE_TRANSCRIPT_ENDPOINT=$BUBBLE_TRANSCRIPT_ENDPOINT
ENV BUBBLE_GET_TRANSCRIPT_ENDPOINT=$BUBBLE_GET_TRANSCRIPT_ENDPOINT
ENV BUBBLE_STORY_ENDPOINT=$BUBBLE_STORY_ENDPOINT

# ensure that any dependent models are downloaded at build-time
RUN python agent.py download-files

# Run the application.
CMD ["python", "agent.py", "start"]
