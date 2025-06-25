ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-alpine AS base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

# Create app directory
WORKDIR /app

# Create a non-privileged user that the app will run under.
ARG UID=10001
ARG APPRAISE_BASE_PATH=/data/appraise
ARG APPRAISE_DATA_PATH="${APPRAISE_BASE_PATH}"/data/
ARG APPRAISE_MEDIA_PATH="${APPRAISE_BASE_PATH}"/media/
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser && \
 mkdir -p "${APPRAISE_DATA_PATH}" && \
 mkdir -p "${APPRAISE_MEDIA_PATH}" && \
 chown -R appuser: "${APPRAISE_BASE_PATH}"

# Install app dependencies + gunicorn
COPY ../Appraise/requirements.txt .

RUN \
 apk add --no-cache postgresql-libs && \
 apk add --no-cache --virtual .build-deps gcc musl-dev postgresql-dev && \
 python3 -m pip install -r requirements.txt --no-cache-dir && \
 python3 -m pip install gunicorn --no-cache-dir && \
 apk --purge del .build-deps

# Copy the source code into the container.
COPY ../Appraise /app
RUN chown -R appuser: /app

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
ENV APPRAISE_ALLOWED_HOSTS='127.0.0.1'
# ENV APPRAISE_CSRF_TRUSTED_ORIGINS='https://*.127.0.0.1'
# ENV APPRAISE_STATIC_ROOT='/data/appraise/data/static'
ENV APPRAISE_MEDIA_ROOT="${APPRAISE_MEDIA_PATH}"
ENV APPRAISE_DATA_DIR="${APPRAISE_DATA_PATH}"
ENV APPRAISE_WSGI_APPLICATION=Appraise.wsgi:application
ENV GUNICORN_EXTRA_ARGS="--access-logfile - --error-logfile -"

# Expose the base path for Appraise data (/data/appraise).
VOLUME "${APPRAISE_BASE_PATH}"

EXPOSE 8000

# Use gunicorn to serve the application.
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:8000 ${APPRAISE_WSGI_APPLICATION} ${GUNICORN_EXTRA_ARGS}"]
