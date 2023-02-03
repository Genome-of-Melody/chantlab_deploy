# Deployment notes

There are other options than Docker to deploy chantlab.

## Via nginx

Easiest way: reverse proxy for just serving a running Angular app started via ng serve.

* Create `/etc/nginx/sites-available/chantlab`. Configure the reverse proxy to the localhost port at which `ng serve` is running (default: 4200).
* Add link to chantlab to `/etc/nginx/sites-enabled`.
* When starting `ng serve`, run with `--host 127.0.0.1 --port 4200 --public-host nginx.listening-on-this-public.url`. (If `--public-host` is not set, there will be an "Invalid host header" page served by nginx.)

The next step is connecting properly from the Angular frontend to the Django backend. 
Again, the minimal solution might be just a reverse proxy to the appropriate port, plus configuring `BACKEND_URL` in `src/app/config`.

