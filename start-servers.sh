#!/bin/bash
set -e
set -x

function waitForPort {
    started=false
    for i in `seq 0 9`; do
        if [ $(curl -I "http://localhost:"$1 | grep "HTTP/1" | cut -d' ' -f2)"" == "404" ]; then
            started=true
            break
        fi
        sleep 1
    done
    if [ ${started} != true ]; then
        echo "server on port "$1" did not start"
        exit -1
    fi
}

DIRHASH=$(pwd | shasum | cut -d" " -f1)

# qabel-drop
cd qabel-drop
if [ -f drop.pid ]; then
    echo "stopping old drop instance"
    cat drop.pid | xargs kill || echo "already gone"
fi
DROP_VENV="venv_"${DIRHASH}
if [ ! -d ${DROP_VENV} ]; then
  virtualenv --no-site-packages --python=python3.4 ${DROP_VENV}
fi
source ${DROP_VENV}"/bin/activate"
pip install -U pip
pip install -r requirements.txt
if [ ! -d config.py ]; then
  cp config.py.example config.py
  sed --in-place "s/'qabel_drop'/'qabel_drop','host':'localhost','port':'5432','username':'qabel','password':'qabel_test'/" config.py
fi
python manage.py create_db
python manage.py runserver --host 0.0.0.0 --port 5000 > drop.log 2>&1 &
echo $! > drop.pid
deactivate
cd ..
waitForPort 5000

# qabel-accounting
cd qabel-accounting
ACCOUNTING_VENV="venv_"${DIRHASH}
if [ -f accounting.pid ]; then
    echo "stopping old accounting instance"
    cat accounting.pid | xargs kill || echo "already gone"
fi
if [ ! -d ${ACCOUNTING_VENV} ]; then
  virtualenv --no-site-packages --always-copy --python=python3.4 ${ACCOUNTING_VENV}
fi
source ${ACCOUNTING_VENV}"/bin/activate"
pip install -U pip
pip install -r requirements.txt
yes "yes" | python manage.py migrate
cp qabel_id/settings/local_settings.example.py qabel_id/settings/local_settings.py
echo -e "\nEMAIL_BACKEND = 'django.core.mail.backends.dummy.EmailBackend'\n" >> qabel_id/settings/local_settings.py
echo -e "\nSECRET_KEY = '=tmcici-p92_^_jih9ud11#+wb7*i21firlrtcqh\$p+d7o*49@'\n" >> qabel_id/settings/local_settings.py
DJANGO_SETTINGS_MODULE=qabel_id.settings.production_settings python manage.py testserver testdata.json --addrport 0.0.0.0:9696 > accounting.log 2>&1 &
echo $! > accounting.pid
deactivate
cd ..
waitForPort 9696

# qabel-block
cd qabel-block
BLOCK_VENV="venv_"${DIRHASH}
if [ -f block.pid ]; then
    echo "stopping old block instance"
    cat block.pid | xargs kill || echo "already gone"
fi
if [ ! -d ${BLOCK_VENV} ]; then
  virtualenv --no-site-packages --always-copy --python=python3.5 ${BLOCK_VENV}
fi
cp config.ini.example config.ini
sed --in-place 's/api_secret=".*"/api_secret="Changeme"/g' config.ini
echo -e "\npsql_dsn='postgres://block_dummy:qabel_test_dummy@localhost/block_dummy'" >> config.ini
source ${BLOCK_VENV}"/bin/activate"
pip install -U pip
pip install -r requirements.txt
cd src

python manage.py dropdb --psql-dsn 'postgres://block_dummy:qabel_test_dummy@localhost/block_dummy'
python manage.py initdb --psql-dsn 'postgres://block_dummy:qabel_test_dummy@localhost/block_dummy'
python run.py --debug --dummy --dummy-log --dummy-cache --apisecret=Changeme --accounting-host=http://localhost:9696 --address=0.0.0.0 --port=9697 --psql-dsn='postgres://block_dummy:qabel_test_dummy@localhost/block_dummy' > ../block.log 2>&1 &
echo $! > ../block.pid
deactivate
cd ../..
waitForPort 9697
