#!/usr/bin/ruby

begin
  require 'forwardable' # Patch for broken Thin...
  require 'find'
  require 'rubygems'
  require 'ramaze'
  require 'sequel'
  require 'construct'
  require 'socket'
  require 'cssmin'
  require 'jsmin'
  require 'json'

  require 'sequel/extensions/migration'
  require 'sequel/extensions/inflector'
  require 'sequel/extensions/blank'
rescue LoadError => e
  puts e
  puts "You probably need to install some packages Cortex Reaver needs. Try: 
apt-get install libmagick9-dev libmysql-ruby;
gem install thin mongrel ramaze sequel yaml erubis BlueCloth rmagick exifr hpricot;"
  exit 255
end

module CortexReaver
  # Paths
  ROOT = File.expand_path(File.join(__DIR__, '..'))
  LIB_DIR = File.expand_path(File.join(ROOT, 'lib', 'cortex_reaver'))
  HOME_DIR = File.expand_path(Dir.pwd)
  
  # Some basic initial requirements
  require File.join(LIB_DIR, 'version')
  require File.join(LIB_DIR, 'config')

  # Reads files from stock_dir and custom_dir matching pattern, and appends
  # their contents. Returns a string.
  def self.collect_files(stock_dir, custom_dir, pattern = /^[^\.].+/, opts = {})
    str = ""
    # Get target files
    files = Dir.entries(stock_dir) | Dir.entries(custom_dir)

    # Reorder files if necessary.
    if order = opts[:order]
      files = (order & files) + (files - order)
    end

    # Read files
    files.each do |file|
      next unless file =~ pattern
      custom_file = File.join(custom_dir, file)
      stock_file = File.join(stock_dir, file)
      if File.exists? custom_file
        str << File.read(custom_file)
      else
        str << File.read(stock_file)
      end
      str << "\n"
    end

    str
  end

  # Compiles CSS files and creates minified version.
  def self.compile_css
    Ramaze::Log.info "Compiling CSS"
    stock_dir = File.join(LIB_DIR, 'public', 'css')
    custom_dir = File.join(config.public_root, 'css')

    # Get CSS files
    FileUtils.mkdir_p(custom_dir)
    css = collect_files(stock_dir, custom_dir, /^((?!style).)*\.css$/, :order => config.css)

    # Write minified CSS
    File.open(File.join(custom_dir, 'style.css'), 'w') do |file|
      file.write CSSMin.minify(css)
    end
  end

  # Compiles JS files and creates minified version.
  def self.compile_js
    Ramaze::Log.info "Compiling JS"
    stock_dir = File.join(LIB_DIR, 'public', 'js')
    custom_dir = File.join(config.public_root, 'js')

    # Get JS files
    FileUtils.mkdir_p(custom_dir)
    js = collect_files(stock_dir, custom_dir, /^((?!site).)*\.js$/, :order => config.js)

    # Write minified JS
    File.open(File.join(custom_dir, 'site.js'), 'w') do |file|
      file.write js #JSMin.minify(js)
    end
  end

  def self.compile_resources
    # Prepare CSS/JS
    self.compile_css
    self.compile_js

    if config.mode == :development
      # Recompile CSS/JS on changes.
      @asset_compiler = Thread.new do
        # Get files to watch
        files = Dir.glob(File.join(LIB_DIR, 'public', 'css', '*.css'))
        files |= Dir.glob(File.join(config.public_root, 'css', '*.css'))
        files |= Dir.glob(File.join(LIB_DIR, 'public', 'js', '*.js'))
        files |= Dir.glob(File.join(config.public_root, 'js', '*.js'))
        files -= [
          File.join(config.public_root, 'css', 'style.css'),
          File.join(config.public_root, 'js', 'site.js')
        ]
        last = {}

        # Get initial modification times.
        files.each do |f|
          last[f] = File.stat(f).mtime
        end

        loop do
          # Check files
          rebuild = false
          files.each do |f|
            mtime = File.stat(f).mtime
            if last[f] < mtime
              last[f] = mtime
              rebuild = true
            end
          end

          if rebuild
            # Recompile
            self.compile_css
            self.compile_js
          end
        
          sleep 2
        end
      end
    end
  end

  # Returns the site configuration
  def self.config
    @config
  end

  def self.config_file
    @config_file || File.join(Dir.pwd, 'cortex_reaver.yaml')
  end

  def self.config_file=(file)
    @config_file = file
  end

  # The total span of items in the CR DB, for copyright notices and such.
  def self.content_range
    return @content_range if @content_range

    @content_range = [Journal, Page, Photograph].inject(nil) do |total, ds|
      begin
        if total
          total | ds.range(:created_on)
        else
          ds.range(:created_on)
        end
      rescue
        # Some range was invalid
        total
      end
    end
    if @content_range.first.kind_of? String 
      @content_range = DateTime.parse(@content_range.begin) .. DateTime.parse(@content_range.end)
    end

    # If there's no content, default to today!
    @content_range ||= Time.now .. Time.now
  end

  # Creates the app directories if they don't exist.
  def self.create_directories
    # view
    if config.view_root
      if not File.directory? config.view_root
        # Try to create a view directory
        begin
          FileUtils.mkdir_p config.view_root
        rescue => e
          Ramaze::Log.warn "Unable to create a view directory at #{config.view_root}: #{e}."
        end
      end
    end

    # public
    if config.public_root and not File.directory? config.public_root
      # Try to create a public directory
      begin
        FileUtils.mkdir_p config.public_root
      rescue => e
        Ramaze::Log.warn "Unable to create a public directory at #{config.public_root}: #{e}."
      end
    end

    # log
    if config[:log_root] and not File.directory? config[:log_root]
      # Try to create a log directory
      begin
        FileUtils.mkdir_p config[:log_root]
        File.chmod 0750, config[:log_root]
      rescue => e
        Ramaze::Log.warn "Unable to create a log directory at #{config[:log_root]}: #{e}. File logging disabled."
        # Disable logging
        config[:log_root] = nil
      end
    end
  end

  def self.db
    @db
  end

  # Prepare Ramaze, create directories, etc.
  def self.init
    # App
    Ramaze.options.app.name = :cortex_reaver
    
    # Helper load path
    Ramaze.options.helpers_helper.paths.unshift LIB_DIR
   
    # Load controllers 
    require File.join(LIB_DIR, 'controller', 'controller')

    # Server options
    Ramaze.options.adapter.handler = config[:adapter]
    Ramaze.options.adapter.host = config[:host]
    Ramaze.options.adapter.port = config[:port]

    # App mode
    case config[:mode]
    when :production
      Ramaze.options.mode = :live
    when :development
      Ramaze.options.mode = :dev
    else
      raise ArgumentError.new("unknown Cortex Reaver mode #{config.mode.inspect}. Expected one of [:production, :development].")
    end
    
    create_directories
    setup_logging
    setup_cache
    compile_resources
    load_plugins
  end

  # Load libraries
  def self.load
    # Load controllers and models
    require File.join(LIB_DIR, 'version')
    require File.join(LIB_DIR, 'config')
    require File.join(LIB_DIR, 'plugin')
    Ramaze::acquire File.join(LIB_DIR, 'snippets', '**', '*')
    Ramaze::acquire File.join(LIB_DIR, 'support', '*')
    require File.join(LIB_DIR, 'cache')
    require File.join(LIB_DIR, 'model', 'model')
  end

  # Load plugins
  def self.load_plugins
    # Create plugin cache
    Ramaze::Cache.add(:plugin)

    # Load plugins
    config.plugins.enabled.each do |plugin|
      Ramaze::Log.info "Loading plugin #{plugin}"
      begin
        require File.join(config.plugin_root, plugin)
      rescue LoadError => e
        require File.join(LIB_DIR, 'plugins', plugin)
      end
    end
  end

  # Reloads the site configuration
  def self.reload_config
    begin
      @config = CortexReaver::Config.load(File.read(config_file))
    rescue Errno::ENOENT
      @config = CortexReaver::Config.new
    end
  end

  # Restart Cortex Reaver
  def self.restart
    begin
      stop
      # Wait for Cortex Reaver to finish, and for the port to become available.
      sleep 2
    ensure
      start
    end
  end

  # Once environment is prepared, run Ramaze
  def self.run
    # Shutdown callback
    at_exit do
      # Remove pidfile
      FileUtils.rm(config.pidfile) if File.exist? config.pidfile
    end

    Ramaze::Log.info "Cortex Reaver #{Process.pid} stalking victims."

    # Run Ramaze
    roots = [LIB_DIR]
    roots.unshift config.root if config.root
    Ramaze.start :root => roots

    puts "Cortex Reaver finished."
  end

  # Load Cortex Reaver environment; do everything except start Ramaze
  def self.setup
    # Connect to DB
    setup_db

    # Load library
    self.load

    # Prepare Ramaze, check directories, etc.
    init
  end

  # Connect to DB. If check_schema is false, doesn't check to see that the
  # schema version is up to date.
  def self.setup_db(check_schema = true)
    unless config
      raise RuntimeError.new("no configuration available!")
    end

    # Connect
    begin
      @db = Sequel.connect(config.database.str)
    rescue => e
      Ramaze::Log.error("Unable to connect to database: #{e}.")
      abort
    end

    # Check schema
    if check_schema and
       Sequel::Migrator.get_current_migration_version(@db) !=
       Sequel::Migrator.latest_migration_version(File.join(LIB_DIR, 'migrations'))

      raise RuntimeError.new("database schema missing or out of date. Please run `cortex_reaver --migrate`.")
    end
  end

  def self.setup_cache
    # Set up cache
    case config.cache
    when :memcache
      Ramaze::Cache::MemCache::OPTIONS[:servers] = config.memcache.servers
      Ramaze::Cache.options.default = Ramaze::Cache::MemCache

      # Cache templates
      Innate::View.options.read_cache = true
    else
      # Cache stub
      Ramaze::Log.warn "Caching disabled."
      Ramaze::Cache.options.default = CortexReaver::Cache::Noop
    end
  end

  def self.setup_logging
    # Clear loggers
    Ramaze::Log.loggers.clear

    unless config.daemon
      # Log to console
      Ramaze::Log.loggers << Logger.new(STDOUT)
    end

    if config.log_root
      # Log to files
      case config.mode
      when :production
        logfile = 'production.log'
        level = Logger::Severity::INFO
      when :development
        logfile = 'development.log'
        level = Logger::Severity::DEBUG

        # Also use SQL log
        db.logger = Logger.new(
          File.join(config.log_root, 'sql.log')
        )
      end

      # Create file logger      
      Ramaze::Log.loggers << Logger.new(
        File.join(config.log_root, logfile)
      )
      Ramaze::Log.level = level
    end
  end

  # Disconnect from DB
  def self.shutdown_db
    @db.disconnect
    @db = nil
  end

  def self.start
    reload_config

    # Check PID
    if File.file? config.pidfile
      pid = File.read(config.pidfile, 20).strip
      abort "Cortex Reaver already running? (#{pid})"
    end

    puts "Activating Cortex Reaver."
    setup

    if config.daemon
      fork do
        # Drop console, create new session
        Process.setsid
        exit if fork

        # Write pidfile
        File.open(config.pidfile, 'w') do |file|
          file << Process.pid
        end

        # Move to homedir; drop creation mask
        Dir.chdir HOME_DIR
        File.umask 0000

        # Drop stream handles
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen(STDOUT)

        # Go!
        run
      end
    else
      # Run in foreground.
      run
    end
  end

  def self.stop
    reload_config

    unless config.pidfile
      abort "No pidfile to stop."
    end

    unless File.file? config.pidfile
      abort "Cortex Reaver not running? (check #{config.pidfile})"
    end

    # Get PID
    pid = File.read(config.pidfile, 20).strip
    unless (pid = pid.to_i) != 0
      abort "Invalid process ID in pidfile (#{pid})."
    end

    puts "Shutting down Cortex Reaver #{pid}..."
    
    # Attempt to end Ramaze nicely.
    begin
      # Try to shut down Ramaze nicely.
      Process.kill('INT', pid)
      puts "Shut down."
      killed = true
    rescue Errno::ESRCH
      # The process doesn't exist.
      puts "No Cortex Reaver with pid #{pid}."
      killed = true
    rescue => e
      begin
        # Try to end the process forcibly.
        puts "Cortex Reaver #{pid} has gone rogue (#{e}); forcibly terminating..."
        Process.kill('KILL', pid)
        puts "Killed."
        killed = true
      rescue => e2
        # That failed, too.
        puts "Unable to terminate Cortex Reaver: #{e2}."
        killed = false
      end
    end

    # Remove pidfile if killed.
    if killed
      begin
        FileUtils.rm(config.pidfile)
      rescue Errno::ENOENT
        # Pidfile gone
      rescue => e
        puts "Unable to remove pidfile #{config.pidfile}: #{e}."
      end
    end
  end
end
