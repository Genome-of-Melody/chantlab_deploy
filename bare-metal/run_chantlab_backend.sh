#!/bin/bash

CHANTLAB_BACKEND_ROOT=/opt/chantlab_backend

# Script that supervisor uses to keep the chantlab back-end running.
if ! ps ax | grep -v grep | grep "chantlab/bin/gunicorn --timeout 600 --workers 4 backend.wsgi:application --bind 0.0.0.0:8000" > /dev/null
then
    # Log restart
    echo "Chantlab backend down; restarting run_chantlab_backend.sh"
    # The right conda environment
    conda activate chantlab
    cd ${CHANTLAB_BACKEND_ROOT}
    # Apply database migrations without prompting for user input
    python manage.py migrate --no-input
    # Collect static files from your various applications into one location
    python manage.py collectstatic --no-input
    # Create superuser admin account to be able to log into the Django project's admin page
    DJANGO_SUPERUSER_PASSWORD=$SUPER_USER_PASSWORD python manage.py createsuperuser --username $SUPER_USER_NAME --email $SUPER_USER_EMAIL --noinput
    # Run the Django application using gunicorn
    gunicorn --timeout 600 --workers 4 backend.wsgi:application --bind 0.0.0.0:8000
fi

