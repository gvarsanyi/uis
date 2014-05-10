
compile:
	chmod a+x coffee/app.coffee
	coffee -o js/ coffee/
	echo '#!/usr/bin/env node' | cat - js/app.js > js/_app.js
	mv js/_app.js js/app.js
	chmod a+x js/app.js
