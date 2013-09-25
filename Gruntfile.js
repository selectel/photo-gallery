module.exports = function(grunt) {
	grunt.initConfig({
		compass: {
			all: {
				config: './config.rb',
			}
		},
		ejs: {
			options: {
				'fs': require('fs'),
			},
			gallery: {
				cwd: 'src',
				src: ['gallery.ejs'],
				dest: 'dist/',
				ext: '.html',
				expand: true
			},
			access: {
				cwd: 'src',
				src: ['access.ejs'],
				dest: 'dist/',
				ext: '.html',
				expand: true
			}
		},
		concat: {
			gallery: {
				files: {'.temp/js/gallery.js': [
					'src/js/vendor/jquery.min.js',
					'src/js/vendor/underscore-min.js',
					'src/js/vendor/jquery.event.move.js',
					'src/js/vendor/jquery.event.swipe.js',
					'src/js/vendor/jquery.popup.js',
					'src/js/vendor/jquery.appear.js',
					'src/js/vendor/backbone-min.js',
					'.temp/js/gallery.js',
				]}
			}
		},
		coffee: {
			options: {

			},
			gallery: {
				files: {
					'.temp/js/gallery.js': 'src/js/gallery.coffee'
				}
			},
			access: {
				files: {
					'.temp/js/access.js': 'src/js/access.coffee'
				}
			},
		},
		uglify: {
			gallery: {
				files: { '.temp/js/gallery.js': ['src/js/vendor/*'] }
			},
			access: {
				files: {'.temp/js/access.js': ['.temp/js/access.js']},
			},
		}
	});

	grunt.loadNpmTasks('grunt-contrib-compass');
	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-uglify');
	grunt.loadNpmTasks('grunt-contrib-concat');
	grunt.loadNpmTasks('grunt-ejs');

	grunt.registerTask('build:access', ['coffee:access', 'compass', 'uglify:access', 'ejs:access']);
	grunt.registerTask('build:gallery', ['coffee:gallery', 'compass', 'uglify:gallery', 'concat:gallery', 'ejs:gallery']);
}