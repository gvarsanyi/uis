
compile:
	chmod a+x ./app.js
	coffee -c patch/*.coffee
	cat resource/service-plugin/class/*.coffee resource/service-plugin/service-plugin.coffee | coffee -s -p > resource/service-plugin.js
	coffee -c resource/karma-wrapper.coffee
