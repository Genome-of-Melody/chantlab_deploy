# Chantlab Deployment

## How to deploy
1. install Docker [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
2. clone this repository `git clone https://github.com/Genome-of-Melody/chantlab_deploy.git`
3. clone all chantlab projects (chantlab frontend, chantlab backend) into this directory 
      ```sh
      cd chantlab_deploy
      git clone https://github.com/Genome-of-Melody/chantlab_backend
      git clone https://github.com/Genome-of-Melody/chantlab_frontend
      ```
   The structure of the chantlab_deploy directory
   ```
   └── chantlab_deploy
      ├── chantlab_backend
      │   ├── data/              # persisted SQLite (chants.db), bind-mounted by compose
      │   ├── Dockerfile
      │   └── ...
      │
      ├── chantlab_frontend
      │   ├── ...
      │   ├── Dockerfile
      │   └── ...
      │
      ├── nginx
      │   ├── chantlab
      │   └── Dockerfile
      │
      ├── bare-metal/            # supervisord scripts for install without Docker
      ├── .env
      │
      └── docker-compose.yaml   # host volume: ./chantlab_backend/data
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
   - ***SUPER_USER_NAME***, ***SUPER_USER_PASSWORD***, ***SUPER_USER_EMAIL*** variables set the super user admin account for the django chantlab backend
   - ***DEBUG_MODE*** specifies whether we run the application in debug ("True") or production ("False") mode
   - optional when the app is not at `/`: ***FORCE_SCRIPT_NAME*** (e.g. `/chantlab`); set ***BACKEND_URL*** to the full public API URL (the Angular base href is derived from it) 
5. Run the application via the docker compose command 
   ```sh
   docker-compose up -d --build
   ```
   Persistence is configured in `docker-compose.yaml`, not in the backend Dockerfile. A Dockerfile cannot map a container path onto a specific host folder; that is a *run-time* bind mount:

   ```yaml
   volumes:
     - ./chantlab_backend/data:/opt/chantlab_backend/data
   ```

   Local `runserver` and Docker both use `chantlab_backend/data/chants.db`. The file survives `docker-compose down` / image rebuilds and can be copied from the host. Stop the backend container first if you need a consistent snapshot.

   If Docker previously created a **folder** named `chants.db`, delete that folder before starting — that happens when a missing *file* is bind-mounted. Always mount the `data/` directory, never the `.db` file itself.

## Deployment of a single subprojects

In case you need to deploy only one of provided projects (chantlab_backend, chantlab_frontend), you can either go through its Dockerfile and follow all installation steps manually, or you can use again Docker
1. install Docker [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
2. clone the project's repo, e.g. `git clone https://github.com/Genome-of-Melody/chantlab_backend`
3. go inside and build the image, e.g.
   ```sh
   cd chantlab_backend
   docker build -t chantlab_backend .
   docker run -p 8000:8000 -v "${PWD}/data:/opt/chantlab_backend/data" chantlab_backend
   ```
   - the backend api runs on the localhost:8000/api/chants
   - in case of chantlab_frontend replace ports 8000:8000 by 4200:4200 (then the frontend runs on the localhost:4200)
   - if you need to set one of environment variables, add them in the last command this way (the list of environmental variables for the specific sub-project could be find in the ./docker-compose.yaml file) 
     
     ```sh
     docker run -e "ALLOWED_HOST=localhost" -e "DEBUG_MODE=False" -p 8000:8000 -v "${PWD}/data:/opt/chantlab_backend/data" chantlab_backend
     ```


## Deploy backend + frontend without Docker (nginx, gunicorn, ng serve, supervisord)

Use this on a shared host (for example a cluster node) where Docker is not available. Configuration lives in **`/etc/environment`**.

Ready-made files are in `bare-metal/`:

| File | Copy to |
|---|---|
| `environment` | merge into `/etc/environment` |
| `run_chantlab_backend.sh` | `/opt/run_chantlab_backend.sh` |
| `run_chantlab_frontend.sh` | `/opt/run_chantlab_frontend.sh` |
| `run_chantlab_backend.conf` | `/etc/supervisor/conf.d/run_chantlab_backend.conf` |
| `run_chantlab_frontend.conf` | `/etc/supervisor/conf.d/run_chantlab_frontend.conf` |
| `chantlab` | `/etc/nginx/sites-available/chantlab` (symlink in `sites-enabled/`) |

Paths `/opt/chantlab_backend` and `/opt/chantlab_frontend` match the Docker layout. If the clones live somewhere else, set `CHANTLAB_BACKEND_ROOT` / `CHANTLAB_FRONTEND_ROOT` at the top of the run scripts. Conda is assumed at `/opt/conda`; if yours is elsewhere, set `CONDA_ROOT` there (or in `/etc/environment`) to the output of `conda info --base`. Supervisord does not load `~/.bashrc`, so the scripts source `$CONDA_ROOT/etc/profile.d/conda.sh` before `conda activate`.

### 1. Install system packages

```sh
# Python / process manager / reverse proxy / MrBayes build deps
sudo apt-get update
sudo apt-get install -y supervisor nginx python3 build-essential git wget cmake \
    libreadline-dev libncurses5-dev zlib1g-dev libssl-dev

# Node 24 (Angular)
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo bash -
sudo apt-get install -y nodejs
sudo npm install -g npm@latest

# MAFFT (used at /opt/conda/bin/mafft by default)
sudo apt-get install -y mafft
# or: conda install -c bioconda mafft
```

Miniconda (if not already present):

```sh
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
bash ~/miniconda.sh -b -p /opt/conda
rm ~/miniconda.sh
/opt/conda/bin/conda init bash
# log out and back in, or: source /opt/conda/etc/profile.d/conda.sh
conda create -n chantlab python=3.11
```

### 2. Clone the apps

```sh
sudo mkdir -p /opt
sudo git clone https://github.com/Genome-of-Melody/chantlab_backend /opt/chantlab_backend
sudo git clone https://github.com/Genome-of-Melody/chantlab_frontend /opt/chantlab_frontend
sudo mkdir -p /opt/chantlab_backend/data
```

### 3. Python and Node dependencies

```sh
source /opt/conda/etc/profile.d/conda.sh
conda activate chantlab
python -m pip install --upgrade pip
pip install -r /opt/chantlab_backend/requirements.txt
pip install chant21==0.4.6 --no-deps

cd /opt/chantlab_frontend
npm install
```

### 4. MrBayes

Phylogeny uses the `mb` binary. Install the volpiano-aware fork the same way as the backend Dockerfile: clone to `/opt/mrbayes`, then `configure` / `make` / `make install` (that puts `mb` in `/usr/local/bin`).

```sh
sudo git clone --depth=1 https://github.com/Genome-of-Melody/mrbayes_volpiano.git /opt/mrbayes
cd /opt/mrbayes
./configure
make
sudo make install
which mb
```

`make install` writes `/usr/local/bin/mb`. The backend calls `mb` on `PATH`; do not skip this step.

### 5. Persistent environment: `/etc/environment`

Set these variables in **`/etc/environment`** (not in the git repos, not in a terminal `export`). Supervisor does not read `~/.bashrc`. Edit that file, then reboot or start a new login so supervisord sees the new values.

```sh
sudo nano /etc/environment
```

Template: `bare-metal/environment`. Put your own `SUPER_USER_*` values there; do not commit real passwords. Replace `example.com` with your public hostname.

```sh
SUPER_USER_NAME="your_admin_name"
SUPER_USER_PASSWORD="your_admin_password"
SUPER_USER_EMAIL="your_admin@example.com"
ALLOWED_HOST="example.com"
DEBUG_MODE="False"
BACKEND_URL="https://example.com/chantlab/api/chants"
PUBLIC_HOST="example.com"
FORCE_SCRIPT_NAME="/chantlab"
MAFFT_PATH="/opt/conda/bin/mafft"
```

| Variable | Used by | Purpose |
|---|---|---|
| `ALLOWED_HOST` | Django | Host header |
| `FORCE_SCRIPT_NAME` | Django + frontend | URL prefix, e.g. `/chantlab`. Frontend run script writes it into `<base href>` in `src/index.html` |
| `MAFFT_PATH` | backend | MAFFT binary (default `/opt/conda/bin/mafft`) |
| `BACKEND_URL` | frontend | written into `src/app/config.json` by `jq` in the run script |
| `PUBLIC_HOST` | `ng serve --public-host` | public hostname |
| `DEBUG_MODE` | Django / Angular | `"False"` for production |
| `SUPER_USER_*` | backend run script | `createsuperuser` on first start |

### 6. Install the run scripts

```sh
sudo cp chantlab_deploy/bare-metal/run_chantlab_backend.sh /opt/run_chantlab_backend.sh
sudo cp chantlab_deploy/bare-metal/run_chantlab_frontend.sh /opt/run_chantlab_frontend.sh
sudo chmod +x /opt/run_chantlab_backend.sh /opt/run_chantlab_frontend.sh
```

Edit the clone paths and conda prefix if they are not under `/opt`:

```sh
# /opt/run_chantlab_backend.sh
CHANTLAB_BACKEND_ROOT=/opt/chantlab_backend
CONDA_ROOT=/opt/conda          # or: conda info --base

# /opt/run_chantlab_frontend.sh
CHANTLAB_FRONTEND_ROOT=/opt/chantlab_frontend
CONDA_ROOT=/opt/conda
```

`run_chantlab_backend.sh` sources `$CONDA_ROOT/etc/profile.d/conda.sh`, activates conda, `cd`s to `CHANTLAB_BACKEND_ROOT`, migrates, collectstatic, then gunicorn.

`run_chantlab_frontend.sh` `cd`s to `CHANTLAB_FRONTEND_ROOT`, writes `BACKEND_URL` into `src/app/config.json` with `jq`, writes `<base href>` in `src/index.html` from `FORCE_SCRIPT_NAME` (or the path prefix of `BACKEND_URL`), then `ng serve`. Do not edit `index.html` or `config.json` after pull.

### 7. Supervisord

Debian/Ubuntu already has `/etc/supervisor/supervisord.conf` with `[include] files = /etc/supervisor/conf.d/*.conf`.

```sh
sudo cp chantlab_deploy/bare-metal/run_chantlab_backend.conf /etc/supervisor/conf.d/run_chantlab_backend.conf
sudo cp chantlab_deploy/bare-metal/run_chantlab_frontend.conf /etc/supervisor/conf.d/run_chantlab_frontend.conf
```

Start (same command as in Docker):

```sh
sudo /usr/bin/python3 /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
```

If supervisord is already running as a systemd service:

```sh
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start chantlab_backend chantlab_frontend
```

Logs:

* `/var/log/run_chantlab_backend.out.log` / `.err.log`
* `/var/log/run_chantlab_frontend.out.log` / `.err.log`

Stop everything before an update:

```sh
sudo supervisorctl stop chantlab_backend chantlab_frontend
# or, if you started supervisord by hand:
pkill -f "supervisord"
pkill -f "gunicorn"
pkill -f "ng serve"
```

### 8. nginx

The nginx site file is `bare-metal/chantlab` (copy to `/etc/nginx/sites-available/chantlab`, symlink from `sites-enabled/`). Set `server_name` to your public hostname.

```sh
sudo cp chantlab_deploy/bare-metal/chantlab /etc/nginx/sites-available/chantlab
sudo ln -sf /etc/nginx/sites-available/chantlab /etc/nginx/sites-enabled/chantlab
sudo nginx -t && sudo systemctl reload nginx
```

## Update with new code

Do **not** rewrite `backend/settings.py`, `src/index.html`, or `src/app/config.json`. Change **`/etc/environment`** only if the public URL, prefix, or MAFFT path changed.

```sh
# 1. Stop running processes
pkill -f "supervisord"
pkill -f "gunicorn"
pkill -f "ng serve"

# 2. Activate conda
conda activate chantlab

# 3. Pull backend
cd /opt/chantlab_backend
git reset --hard
git pull
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install chant21==0.4.6 --no-deps

# 4. Pull frontend
cd /opt/chantlab_frontend
git reset --hard
git pull
npm install -g npm@latest
npm install

# 5. Start again
/usr/bin/python3 /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
```

`git reset --hard` restores stock `config.json`. The frontend run script writes `BACKEND_URL` from `/etc/environment` into that file with `jq`.
