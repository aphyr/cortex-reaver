#!/usr/bin/ruby

begin
  require 'find'
  require 'rubygems'
  require 'ramaze'
  require 'sequel'
  require 'yaml'
  require 'socket'

  require 'sequel/extensions/migration'
  require 'sequel/extensions/inflector'
  require 'sequel/extensions/blank'
rescue LoadError => e
  puts e
  puts "You probably need to install some packages Cortex Reaver needs. Try: 
apt-get install librmagick-ruby libmysql-ruby;
gem install thin mongrel ramaze sequel yaml erubis BlueCloth rmagick exifr hpricot builder coderay;"
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

  def self.db
    @db
  end

  # Prepare Ramaze, create directories, etc.
  def self.init
    # App
    Ramaze.options.app.name = :cortex_reaver
    
    # Root directory
    Ramaze::App[:cortex_reaver].options.roots = [LIB_DIR]
    if config[:root]
      Ramaze::App[:cortex_reaver].options.roots.unshift(config[:root])
    end

    # Server options
    Ramaze.options.adapter.handler = config[:adapter]
    Ramaze.options.adapter.host = config[:host]
    Ramaze.options.adapter.port = config[:port]

    # Check directories
    if config[:root] and not File.directory? config.public_root
      # Try to create a public directory
      begin
        FileUtils.mkdir_p config[:public_root]
      rescue => e
        Ramaze::Log.warn "Unable to create a public directory at #{config.public_root}: #{e}."
      end
    end
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

    # Clear loggers
    Ramaze::Log.loggers.clear

    unless config[:daemon]
      # Log to console
      Ramaze::Log.loggers << Logger.new(STDOUT)
    end 

    case config[:mode]
    when :production
      Ramaze.options.mode = :live
      
      # Set up cache
      case config[:cache]
        when :memcache
        Ramaze::Cache.options.default = Ramaze::Cache::MemCache
      end

      if config[:log_root]
        # Log to file
        Ramaze::Log.loggers << Logger.new(
          File.join(config[:log_root], 'production.log')
        )
        Ramaze::Log.level = Logger::Severity::INFO
      end
    when :development
      Ramaze.options.mode = :dev

      if config[:log_root]
        # Log to file
        Ramaze::Log.loggers << Logger.new(
          File.join(config[:log_root], 'development.log')
        )
        Ramaze::Log.level = Logger::Severity::DEBUG

        # Also use SQL log
        db.logger = Logger.new(
          File.join(config[:log_root], 'sql.log')
        )
      end
    else
      raise ArgumentError.new("unknown Cortex Reaver mode #{config[:mode].inspect}. Expected one of [:production, :development].")
    end

    # Prepare view directory
    if config.view_root
      if not File.directory? config.view_root
        # Try to create a view directory
        begin
          FileUtils.mkdir_p config.view_root
        rescue => e
          Ramaze::Log.warn "Unable to create a view directory at #{config[:view_root]}: #{e}."
        end
      end
    end

    # Load plugins
    config[:plugins].each do |plugin|
      Ramaze::Log.info "Loading plugin #{plugin}"
      require File.join(config[:plugin_root], plugin)
    end
  end

  # Load libraries
  def self.load
    # Load controllers and models
    require File.join(LIB_DIR, 'config')
    require File.join(LIB_DIR, 'plugin')
    require File.join(LIB_DIR, 'version')
    Ramaze::acquire File.join(LIB_DIR, 'snippets', '**', '*')
    Ramaze::acquire File.join(LIB_DIR, 'support', '*')
    require File.join(LIB_DIR, 'model', 'model')
    Ramaze::acquire File.join(LIB_DIR, 'helper', '*')
    require File.join(LIB_DIR, 'controller', 'controller')
  end

  # Reloads the site configuration
  def self.reload_config
    @config = CortexReaver::Config.new(config_file)
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
      FileUtils.rm(config[:pidfile]) if File.exist? config[:pidfile]
    end

    Ramaze::Log.info "Cortex Reaver #{Process.pid} stalking victims."

    # Run Ramaze
#    Ramaze.start :root => [config[:root], LIB_DIR]
    Ramaze.start :root => LIB_DIR

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

  # Connect to DB. If check_schema is false, doesn't check to see that the schema
  # version is up to date.
  def self.setup_db(check_schema = true)
    unless config
      raise RuntimeError.new("no configuration available!")
    end

    # Build Sequel connection string
    unless (string = config[:database]).is_a? String
      d = config[:database]
      string = "#{d[:driver]}://#{d[:user]}:#{d[:password]}@#{d[:host]}/#{d[:database]}"
    end

    # Connect
    begin
      @db = Sequel.connect(string)
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

  # Disconnect from DB
  def self.shutdown_db
    @db.disconnect
    @db = nil
  end

  def self.start
    reload_config

    # Check PID
    if File.file? config[:pidfile]
      pid = File.read(config[:pidfile], 20).strip
      abort "Cortex Reaver already running? (#{pid})"
    end

    puts "Activating Cortex Reaver."
    setup

    # Check port availability
#    begin
#      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
#      sockaddr = Socket.pack_sockaddr_in(*[config[:port], config[:host]])
#      socket.bind(sockaddr)
#      socket.close
#    rescue => e
#      abort "Unable to bind to port #{config[:host]}:#{config[:port]} (#{e})"
#    end

    if config[:daemon]
      fork do
        # Drop console, create new session
        Process.setsid
        exit if fork

        # Write pidfile
        File.open(config[:pidfile], 'w') do |file|
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

    unless config[:pidfile]
      abort "No pidfile to stop."
    end

    unless File.file? config[:pidfile]
      abort "Cortex Reaver not running? (check #{config[:pidfile]})"
    end

    # Get PID
    pid = File.read(config[:pidfile], 20).strip
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
        FileUtils.rm(config[:pidfile])
      rescue Errno::ENOENT
        # Pidfile gone
      rescue => e
        puts "Unable to remove pidfile #{config[:pidfile]}: #{e}."
      end
    end
  end
end
