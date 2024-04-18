# Chantlab Deployment

## How to deploy
1. install Docker [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
2. clone this repository `git clone https://github.com/Genome-of-Melody/chantlab_deploy.git`
3. clone all chantlab projects (chantlab frontend, chantlab backend, genomel editor) into this directory 
      ```sh
      cd chantlab_deploy
      git clone https://github.com/Genome-of-Melody/chantlab_backend
      git clone https://github.com/Genome-of-Melody/chantlab_frontend
      git clone https://github.com/Genome-of-Melody/genomel_editor
      ```
   The structure of the chantlab_deploy directory
   ```
   └── chantlab_deploy
      ├── chantlab_backend
      │   ├── ...
      │   ├── Dockerfile
      │   └── ...
      │
      ├── chantlab_frontend
      │   ├── ...
      │   ├── Dockerfile
      │   └── ...
      │
      ├── genomel_editor
      │   ├── ...
      │   ├── Dockerfile
      │   └── ...
      │
      ├── nginx
      │   ├── chantlab
      │   └── Dockerfile
      │
      ├── .env
      │
      └── docker-compose.yaml
   ```

4. set the environmental variables in the `.env` file, e.g.
   ```
   PUBLIC_URL="localhost"
   SUPER_USER_NAME="super_user_name"
   SUPER_USER_PASSWORD="password"
   SUPER_USER_EMAIL="email@email.com"
   DEBUG_MODE="False"
   ``` 
   - ***PUBLIC_URL*** stands for the URL that the application will be running on (e.g. chantlab.mua.cas.cz, localhost, etc.)
   - ***SUPER_USER_NAME***, ***SUPER_USER_PASSWORD***, ***SUPER_USER_EMAIL*** variables set the super user admin account for django chantlab backend and genomel editor
   - ***DEBUG_MODE*** specifies whether we run the application in debug ("True") or production ("False") mode 
5. Run the application via the docker compose command 
   ```sh
   docker-compose up -d --build
   ```

## Deployment of a single subprojects

In case you need to deploy only one of provided projects (chantlab_backend, genomel_editor, ...), you can either go through its Dockerfile and follow all installation steps manually, or you can use again Docker
1. install Docker [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
2. clone the project's repo, e.g. `git clone https://github.com/Genome-of-Melody/chantlab_backend`
3. go inside and build the image, e.g.
   ```sh
   cd chantlab_backend
   docker build -t chantlab_backend .
   docker run -p 8000:8000 chantlab_backend
   ```
   - the backend api runs on the localhost:8000/api/chants
   - in case of chantlab_frontend replace ports 8000:8000 by 4200:4200 (then the frontend runs on the localhost:4200)
   - in case of genomel_editor replace ports 8000:8000 by 7999:7999 (then the genomel editor runs on the localhost:7999)
   - if you need to set one of environment variables, add them in the last command this way (the list of environmental variables for the specific sub-project could be find in the ./docker-compose.yaml file) 
     
     ```sh
     docker run -e "ALLOWED_HOST=localhost" -e "DEBUG_MODE=False" -p 8000:8000 chantlab_backend
     ```


## Notes
There are other options than Docker to deploy chantlab.

### Via nginx and dev servers
Easiest way: reverse proxy for just serving a running Angular app started via ng serve.

* Create `/etc/nginx/sites-available/chantlab`. Configure the reverse proxy to the localhost port at which `ng serve` is running (default: 4200). Note that the `server_name` must correspond to the public-facing URL.
* Add link to chantlab to `/etc/nginx/sites-enabled`.
* When starting `ng serve`, run with `--host 127.0.0.1 --port 4200 --public-host nginx.listening-on-this-public.url`. (If `--public-host` is not set, there will be an "Invalid host header" page served by nginx.)
* Add reverse proxy entry to nginx config for `location /api/chants` that points to `http://localhost:8000/api/chants`.
* Configure `BACKEND_URL` in `src/app/config` to `nginx.listening-on-this-public.url/api/chants`
* Add `nginx.listening-on-this-public.url` to Django settings `ALLOWED_HOSTS` (otherwise you will get a `400 Bad Request` error for any requests to the backend).

Next steps: running Django properly via gunicorn, and serving angular from a built distribution, because using dev servers is not recommended for a production environment.

Persistence is currently handled by `supervisord`, with two scripts in `$HOME/chantlab_deployment`.


### ToDo
 - webhook chantlab_backend, chantlab_frontend and genomel_editor with their github repos commits into the main branch 
   - GitHub Actions in each repo to build and push images into private Docker Hub repo
   - docker-compose.yaml uses watchtower image to monitor Docker Hub changes
   - the third step in deployment could be ignored then