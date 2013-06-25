all: coffee css index

coffee:
	coffee -c js/gallery.coffee
	uglifyjs js/vendor/jquery.min.js js/vendor/underscore-min.js js/vendor/backbone-min.js js/vendor/jquery.event.move.js js/vendor/jquery.event.swipe.js js/vendor/jquery.appear.js js/vendor/jquery.popup.js js/gallery.js -o js/gallery.min.js

css:
	compass compile
	sqwish style.css -o style.min.css

index:
	node ./build-index.js
