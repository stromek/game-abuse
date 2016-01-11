'use strict';


module.exports = (grunt) ->

  #Project configuration
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

  
    watch:
      coffee:
        files: ['public/js/*.coffee', 'public/js/**/*.coffee']
        tasks: ['coffee:local']
        options:
          livereload : true
          debounceDelay : 100

      views:
        files: ['views/*.jade']
        options:
          livereload : true
          debounceDelay : 100

      stylus:
        files: ['public/css/*.styl']
        # tasks: ['stylus:local']
        options:
          livereload : true

    stylus:
      local:
        expand : true
        src : ['css/*.styl']
        ext : '.styl.css'

    coffee:
      options:
        bare: true

      local:
        expand: true
        src : ['public/js/*.coffee', 'routes/*.coffee']
        ext : '.coffee.js'

      # global:
      #   expand: true
      #   cwd: 'htdocs'
      #   src: ['*.coffee', '**/*.coffee']
      #   dest: 'htdocs'
      #   ext: '.coffee.js'

  
    
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-stylus');  

  ## Default task(s).
  grunt.registerTask('default', ['watch']);
