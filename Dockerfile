ARG PYTHON_VERSION=3.12

# Stage 1: Builder -Installs deps on a python venv
FROM python:${PYTHON_VERSION}-alpine AS builder

# Create app directory
WORKDIR /app

# Add build deps
RUN apk add --no-cache --virtual .build-deps gcc musl-dev postgresql-dev

# Creates the python virtual environment and installs app required packages
COPY ./requirements.txt .
RUN python -m venv /opt/venv \
 && /opt/venv/bin/pip install -r requirements.txt --no-cache-dir \
 && /opt/venv/bin/pip install gunicorn --no-cache-dir

# Stage 2: Final - Creates the production App image
FROM python:${PYTHON_VERSION}-alpine AS base

# Install SO runtime deps
RUN apk add --no-cache postgresql-libs

# Create a non-privileged user that the app will run under.
ARG UID=10001
ARG APPRAISE_BASE_PATH=/data/appraise
ARG APPRAISE_DATA_PATH="${APPRAISE_BASE_PATH}"/data/
ARG APPRAISE_MEDIA_PATH="${APPRAISE_BASE_PATH}"/media/
RUN addgroup -S -g "${UID}" appgroup \
 && adduser -S -G appgroup -h /home/appuser -u "${UID}" appuser \
 && mkdir -p /home/appuser/app \
 && chown -R appuser: /home/appuser/app \
 && mkdir -p "${APPRAISE_DATA_PATH}" \
 && mkdir -p "${APPRAISE_MEDIA_PATH}" \
 && chown -R appuser: "${APPRAISE_BASE_PATH}"

# Copy the python virtual environment from the builder
COPY --chown=appuser:appgroup --from=builder /opt/venv /opt/venv

# Sets the workdir to the app directory
WORKDIR /home/appuser/app

# Copy the source code into the container.
COPY --chown=appuser:appgroup . .

# Switch to the non-privileged user to run the application.
USER appuser

# Set some default environment variables for the application.
# These can be overridden at runtime.
# Defined in Appraise/settings.py
# ENV APPRAISE_DEBUG=True
# ENV APPRAISE_TEMPLATE_DEBUG=True
# ENV APPRAISE_ADMINS=
# ENV APPRAISE_SECRET_KEY=
# ENV APPRAISE_DB_ENGINE=
# ENV APPRAISE_DB_NAME=
# ENV APPRAISE_DB_USER=
# ENV APPRAISE_DB_PASSWORD=
# ENV APPRAISE_DB_HOST=
# ENV APPRAISE_DB_PORT=
# ENV APPRAISE_DB_OPTIONS="{'sslmode': 'require'}"
# ENV APPRAISE_CSRF_TRUSTED_ORIGINS='https://*.127.0.0.1'
# ENV APPRAISE_STATIC_ROOT='/data/appraise/data/static'

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    APPRAISE_ALLOWED_HOSTS='127.0.0.1' \
    APPRAISE_MEDIA_ROOT="${APPRAISE_MEDIA_PATH}" \
    APPRAISE_DATA_DIR="${APPRAISE_DATA_PATH}" \
    APPRAISE_WSGI_APPLICATION=Appraise.wsgi:application \
    GUNICORN_EXTRA_ARGS="--access-logfile - --error-logfile -"

# Expose the base path for Appraise data (/data/appraise).
VOLUME "${APPRAISE_BASE_PATH}"

EXPOSE 8000
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:8000 ${APPRAISE_WSGI_APPLICATION} ${GUNICORN_EXTRA_ARGS}"]
