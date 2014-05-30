#/bin/sh

mkdir -p node_modules
cd node_modules
git clone https://github.com/andrew/node-sass.git
cd node-sass
git checkout 16f7845f60abd9e57d1540c640d7476cf13eb2d4
git submodule init
git submodule update
npm install
npm install -g node-gyp
echo cwd `pwd`
node-gyp rebuild
