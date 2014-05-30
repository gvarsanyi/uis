#/bin/sh

if [ "$USER" = "root" ]; then
  if [ -d "/var/root" ]; then
    HOME="/var/root"
  elif [ -d "/root" ]; then
    HOME="/root"
  fi
fi

SELF=$(readlink -m $0)
BASEDIR=$(dirname $SELF)

rm -rf $BASEDIR/node_modules/node-sass
cd $BASEDIR/node_modules
git clone https://github.com/andrew/node-sass.git
cd node-sass
git checkout 16f7845f60abd9e57d1540c640d7476cf13eb2d4
git submodule init
git submodule update
npm install
command -v node-gyp >/dev/null 2>&1 || npm install -g node-gyp
node-gyp rebuild
