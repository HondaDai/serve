require 'pathname'
require 'serve/out'

#
# Serve::Project.new(options).create
# Serve::Project.new(options).convert
#
module Serve
  class Project
    attr_reader :name, :location, :framework
    
    def initialize(options)
      @name       = options[:name]
      @location   = normalize_location(options[:directory], @name)
      @full_name  = git_config('user.name') || 'Your Full Name'
      @framework  = options[:framework]
    end
    
    
    ##
    # Create
    #
    # create a new Serve project
    #
    def create
      setup_base
      %w(
        public/images
        public/javascripts
        public/stylesheets
        sass
      ).each { |path| make_path path } 
      install_javascript_framework
    end
    
    
    ##
    # Convert
    #
    # convert an existing compass project to a
    # server project
    #
    def convert
      setup_base
      move_file 'images', 'public/'
      move_file 'stylesheets', 'public/'
      move_file 'javascripts', 'public/'
      move_file 'src', 'sass'
      install_javascript_framework
    end
    
    
    private
      
      include Serve::Out
      
      ##
      # Setup Base
      #
      # Files required for both a new server project
      # and for an existing compass project.
      #
      def setup_base
        %w(
          .
          public
          tmp
          views
        ).each { |path| make_path path }
        create_file 'config.ru',       config_ru
        create_file 'LICENSE',         license
        create_file '.gitignore',      gitignore
        create_file 'compass.config',  compass_config
        create_file 'README.markdown', readme
        create_empty_file 'tmp/restart.txt'
      end
      
      
      ##
      # Install a JavaScript Framework
      #
      def install_javascript_framework
        if @framework
          action 'installing', @framework
          Serve::JavaScript.new(@location).install(@framework)
        end
      end
      
      
      ##
      # Reads template for compass.config
      #
      def compass_config
        read_template 'compass_config'
      end
      
      
      ##
      # Reads template for config.ru
      #
      def config_ru
        read_template 'config_ru'
      end
      
      ##
      # Reads template for git ignore file
      #
      def gitignore
        read_template 'gitignore'
      end
      
      
      ##
      # Reads template for project license
      #
      def license
        read_template 'license'
      end
      
      
      ##
      # Reads template for project README
      #
      def readme
        read_template 'readme'
      end
      
      
      ##
      # Read and eval a template by name
      #
      def read_template(name)
        contents = IO.read(normalize_path(File.dirname(__FILE__), "templates", name))
        instance_eval "%{#{contents}}"
      end
      
      
      ##
      # Create file
      #
      def create_file(file, contents)
        path = normalize_path(@location, file)
        unless File.exists? path
          action "create", path
          File.open(path, 'w+') { |f| f.puts contents }
        else
          action "exists", path
        end
      end
      
      ##
      # Create empty file
      #
      def create_empty_file(file)
        path = normalize_path(@location, file)
        FileUtils.touch(path)
      end
      
      
      ##
      # Make directory for a given path
      #
      def make_path(path)
        path = normalize_path(@location, path)
        unless File.exists? path
          action "create", path
          FileUtils.mkdir_p(path)
        else
          action "exists", path
        end
      end
      
      
      ##
      # Moves a file at @location + from => @location + to
      # 
      def move_file(from, to)
        from_path = normalize_path(@location, from)
        to_path = normalize_path(@location, to)
        if File.exists? from_path
          action "move", "#{@location}{#{from} => #{to}}"
          FileUtils.mv from_path, to_path
        end
      end
      
      
      ##
      # Convert dashes and spaces to underscores
      #
      def underscore(string)
        string.gsub(/-|\s+/, '_')
      end
      
      
      ##
      # Grab data from the git config file if it exists
      #
      def git_config(key)
        value = `git config #{key}`.chomp
        value.empty? ? nil : value
      end
      
      
      ##
      # Build the target directory
      #
      def normalize_location(path, name = nil)
        path = File.join(path, underscore(name)) if name
        path = normalize_path(path)
        path
      end
      
      ##
      # Normalize a path relative to the current working directory
      #
      def normalize_path(*paths)
        path = File.join(*paths)
        Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(Dir.pwd)).to_s
      end
      
      
  end
end