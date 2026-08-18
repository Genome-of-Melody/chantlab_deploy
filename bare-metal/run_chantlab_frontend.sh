#!/bin/bash
CHANTLAB_FRONTEND_ROOT=/opt/chantlab_frontend

echo $PUBLIC_HOST
echo $DEBUG_MODE
echo $BACKEND_URL


# Script that supervisor uses to keep the chantlab front-end running.
if ! ps ax | grep -v grep | grep -e "ng serve --configuration production --host 127.0.0.1 --port 4200 --public-host $PUBLIC_HOST --serve-path chantlab" -e "ng serve --host 127.0.0.1 --port 4200 --public-host $PUBLIC_HOST --serve-path chantlab" > /dev/null
then
    # Log restart
    echo "Chantlab frontend down; restarting run_chantlab_frontend.sh"
    conda activate chantlab

    cd ${CHANTLAB_FRONTEND_ROOT}
    # Set the current BACKEND_URL
    jq ".BACKEND_URL = \"${BACKEND_URL}\"" ./src/app/config.json > ./src/app/config_tmp.json
    mv "./src/app/config_tmp.json" "./src/app/config.json"

    # Run angular project
   if [ "$DEBUG_MODE" = "False" ]; then
       ./node_modules/.bin/ng serve --configuration production --host "127.0.0.1" --port 4200 --public-host $PUBLIC_HOST --serve-path chantlab
   else
       ./node_modules/.bin/ng serve --host "127.0.0.1" --port 4200 --public-host $PUBLIC_HOST --serve-path chantlab
   fi
fi
