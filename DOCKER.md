# Appraise Application - Docker Compose Setup

This README provides instructions on how to set up and run the Appraise application using Docker Compose, including database (PostgreSQL or SQLite) setup, static files collection, and superuser creation.

* [Prerequisites](#prerequisites)
* [Setup](#setup)
* [Usage](#usage)
* [Starting a campaign](#starting-a-campaign)
* [Environment Variables](#environment-variables)

## Prerequisites

Before you begin, ensure you have the following installed on your system:

* **Docker:** [Install Docker](https://docs.docker.com/get-docker/)
* **Docker Compose:** Docker Compose is usually included with Docker Desktop installations. If not, [install Docker Compose](https://docs.docker.com/compose/install/).

## Setup

1.  **Clone the Repository (if you haven't already):**
    ```bash
    git clone [https://github.com/AppraiseDev/Appraise.git](https://github.com/AppraiseDev/Appraise.git)
    cd Appraise
    ```

2.  **Ensure Docker Configuration Files:**
    Make sure you have your `Dockerfile`, `compose-pgsql.yml`, and `compose-sqlite.yml` in the container directory of the project.

3.  **Environment Variables (Optional but Recommended):**
    For sensitive information and environment-specific settings (like `APPRAISE_SECRET_KEY`, `DEBUG`, and database credentials), create a `.env` file in the same directory as your Docker Compose files. Docker Compose will automatically load variables from this file.

    Example `.env` file:
    ```env
    # .env
    APPRAISE_DB_NAME=appraise_db
    APPRAISE_DB_USER=appraise_user
    APPRAISE_DB_PASSWORD=your_secure_db_password
    APPRAISE_SECRET_KEY=your_django_secret_key_here # IMPORTANT: Change this for production!
    DEBUG=True # Set to False for production
    ```

## Usage

### 1. Starting Services

To start the application in detached (background) mode, choose your desired database backend and run the respective command.

#### a. With PostgreSQL (e.g., Production/Staging Setup)

To use the PostgreSQL database backend:

```bash
docker-compose -f compose-pgsql.yml up -d --build
```

#### b. With SQLite (e.g., Development/Local Testing Setup)

To use the SQLite database backend:

```bash
docker-compose -f compose-sqlite.yml up -d --build --no-cache
```

### 2. Creating a Superuser

This command must be run after your services are up and running. Replace `<DB_ENGINE>` with `pgsql` or `sqlite` depending on your setup.

```bash
docker-compose -f compose-<DBEngine>.yml run --rm web python3 manage.py createsuperuser
```

### 3. Collecting Static Files

You should run it after your services are up and running.

```bash
docker-compose -f compose-<DBEngine>.yml run --rm web python3 manage.py collectstatic --no-post-process
```

### 4. Accessing the Application
Once your services are running, you can access your Appraise application in your web browser at:

[http://localhost:8000](http://localhost:8000)

You can login with the superuser created at [step 2](#2-creating-a-superuser).

### 5. Checking the logs

To see services logs:

```bash
docker-compose -f compose-<DBEngine>.yml logs [-f] [web|bd]
```
Optionaly use `web` or `db` to filter logs for a specific service and `-f` to follow the logs in realtime.

Appraise saves the application log at `<data_volume>/data/appraise.log`

### 6. Stopping Services
To stop and remove the containers, networks, and optionaly the volumes created by docker-compose up:

```bash
docker-compose -f compose-<DBEngine>.yml down [--volumes]
```

**Caution: Using --volumes will delete your persistent data, so use it carefully!**

## Starting a campaign

The [`Examples`](../Examples/) directory contains a few examples of existing annotation campaigns.

You can execute then in the web container by just prefixing the command with: `docker-compose -f compose-<DBEngine>.yml run --rm web`

```bash
# See Examples/MQM+ESA/README.md

# Create the output directory in the persistent volume
docker-compose -f compose-<DBEngine>.yml run --rm web mkdir -p /data/appraise/campaigns/MQM+ESA/

# Create the campaign
docker-compose -f compose-<DBEngine>.yml run --rm web \
python3 manage.py StartNewCampaign Examples/MQM+ESA/manifest_esa.json \
    --batches-json Examples/MQM+ESA/batches_esa.json \
    --csv-output /data/appraise/campaigns/MQM+ESA/output.csv
```

To create your own campaigns, you need to make your _manifest_ and _batches_ files accessible inside the container and then pointing to their location during campaign creation.
This can be achieved in severeal ways, such as putting the files in a mounted volume (e.g., `appraise_app_data`, or some folder bind-mounted), or using `docker cp <host_file> <web_container_id>:<container_path>`.

**Remember to save the output to a persistent volume or to copy it to the host before stopping the container, otherwise you will lose the file when the container stops.**

## Environment Variables

The Appraise application utilizes the following environment variables for configuration:

* `APPRAISE_DEBUG`
* `APPRAISE_TEMPLATE_DEBUG`
* `APPRAISE_ADMINS`
* `APPRAISE_SECRET_KEY`
* `APPRAISE_HEALTH_CHECK_TOKEN`
* `APPRAISE_DB_ENGINE`
* `APPRAISE_DB_NAME`
* `APPRAISE_DB_USER`
* `APPRAISE_DB_PASSWORD`
* `APPRAISE_DB_HOST`
* `APPRAISE_DB_PORT`
* `APPRAISE_DB_OPTIONS`
* `APPRAISE_DB_EXTRA_SETTINGS`
* `APPRAISE_ALLOWED_HOSTS`
* `APPRAISE_CSRF_TRUSTED_ORIGINS`
* `APPRAISE_STATIC_ROOT`
* `APPRAISE_MEDIA_ROOT`
* `APPRAISE_DATA_DIR`
* `APPRAISE_WSGI_APPLICATION`
* `GUNICORN_EXTRA_ARGS`

## Docker Hub Image

A pre-built image is available from [https://hub.docker.com/r/rsn86/appraise](https://hub.docker.com/r/rsn86/appraise)

