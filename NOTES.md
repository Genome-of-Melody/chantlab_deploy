# Deployment notes

There are other options than Docker to deploy chantlab.

## Via nginx and dev servers

Easiest way: reverse proxy for just serving a running Angular app started via ng serve.

* Create `/etc/nginx/sites-available/chantlab`. Configure the reverse proxy to the localhost port at which `ng serve` is running (default: 4200). Note that the `server_name` must correspond to the public-facing URL.
* Add link to chantlab to `/etc/nginx/sites-enabled`.
* When starting `ng serve`, run with `--host 127.0.0.1 --port 4200 --public-host nginx.listening-on-this-public.url`. (If `--public-host` is not set, there will be an "Invalid host header" page served by nginx.)
* Add reverse proxy entry to nginx config for `location /api/chants` that points to `http://localhost:8000/api/chants`.
* Configure `BACKEND_URL` in `src/app/config` to `nginx.listening-on-this-public.url/api/chants`
* Add `nginx.listening-on-this-public.url` to Django settings `ALLOWED_HOSTS` (otherwise you will get a `400 Bad Request` error for any requests to the backend).

Next steps: running Django properly via gunicorn, and serving angular from a built distribution, because using dev servers is not recommended for a production environment.
