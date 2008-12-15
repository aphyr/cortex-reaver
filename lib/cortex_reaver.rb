#!/usr/bin/ruby

begin
  require 'rubygems'
  require 'ramaze'
  require 'sequel'
  require 'yaml'
rescue LoadError => e
  puts e
  puts "You probably need to install some packages Cortex Reaver needs. Try: 
apt-get install librmagick-ruby;
gem install mongrel ramaze sequel yaml erubis BlueCloth rmagick exifr hpricot builder;"
  exit 255
end

module CortexReaver
  ROOT = File.expand_path(__DIR__/'..')
  LIB_DIR = ROOT/:lib/:cortex_reaver
  
  # We need the configuration class before everything.
  require LIB_DIR/:config

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

  # Sets the configuration file and reloads
  def self.configure(file = nil)
    if file
      self.config_file = file
    end
    reload_config
  end

  def self.db
    @db
  end

  # Load libraries
  def self.load
    # Prepare Ramaze
    Ramaze::Global.public_root = LIB_DIR/:public
    Ramaze::Global.view_root = config[:view_root]

    # Load controllers and models
    acquire LIB_DIR/:snippets/'**'/'*'
    acquire LIB_DIR/:support/'*'
    acquire LIB_DIR/:model/'*'
    acquire LIB_DIR/'**'/'*'
    acquire LIB_DIR/:controller/'*'
    acquire LIB_DIR/:helper/'*'
  end

  # Reloads the site configuration
  def self.reload_config
    @config = CortexReaver::Config.new(config_file)
  end

  def self.start
    # Load configuration
    reload_config
    
    # Connect to db
    setup_db

    # Load library
    self.load

    # Go!
    Ramaze.start :adapter => config[:adapter], :port => config[:port]
  end

  # Load CortexReaver environment; do everything except start Ramaze
  def self.setup(file)
    # Load config
    @config_file = file
    reload_config

    # Connect to DB
    setup_db

    # Load library
    self.load
  end

  # Connect to DB
  def self.setup_db
    unless config
      raise RuntimeError.new("no configuration available!")
    end

    unless (string = config[:database]).is_a? String
      d = config[:database]
      string = "#{d[:driver]}://#{d[:user]}:#{d[:password]}@#{d[:host]}/#{d[:database]}"
    end

    @db = Sequel.connect(string)
  end

  # Disconnect from DB
  def self.shutdown_db
    @db.disconnect
    @db = nil
  end
end
