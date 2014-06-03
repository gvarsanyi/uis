#/bin/sh


if [ -z "$1" ]; then
  echo "Missing target directory for node-sass installation"
  exit 1
fi

echo "Attempting to install node-sass from git to: $1"

rm -rf $1
mkdir -p $1 && cd $1 && (
  git clone https://github.com/andrew/node-sass.git ./
  git checkout 16f7845f60abd9e57d1540c640d7476cf13eb2d4
  git submodule init
  git submodule update
  npm install
  command -v node-gyp >/dev/null 2>&1 || sudo npm install -g node-gyp
  node-gyp rebuild
)
