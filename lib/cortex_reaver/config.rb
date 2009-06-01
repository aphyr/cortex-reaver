module CortexReaver
  # Contains site-specific configuration information for a CortexReaver site.
  class Config < Hash
    # Pass a YAML file with configuration options. At a minimum, it should specify
    # :database = {:proto, :username, :pasword, :host, :database}
    # or :database = "sequel_connect_string"
    # :root        - The directory containing public/, layout/, and view/. 
    #                Defaults to HOME_DIR.
    # :log_root    - The directory that Cortex Reaver should log to. Defaults to
    #                HOME_DIR/log. If nil, file logging disabled.
    # :plugin_root - The directory that Cortex Reaver plugins live in. Defaults
    #                to HOME_DIR/plugins.
    # :mode        - Cortex Reaver mode: either :development or :production
    # :daemon      - Whether to daemonize or not. Defaults to :true if :mode
    #                is :production, otherwise nil.
    # :adapter     - The Ramaze adapter name (default 'thin')
    # :cache       - The Ramaze cache to use (default: :memory)
    # :host        - Host to bind to 
    # :port        - Port to bind to (default 7000)
    # :pidfile     - Process ID file for this server. Defaults to 
    #                HOME_DIR/cortex_reaver_<host>_<port>.pid
    # :compile_views - Whether to cache compiled view templates. Defaults to
    #                  true in production mode.
    # :plugins     - Which plugins to enable. Defaults to [].
    #
    # Site configuration options
    # :site = {
    #   :name        - The name of the site
    #   :author      - The site author's name
    #   :keywords    - Keywords describing the site
    #   :description - A short description of the site.
    # }
    def initialize(file)
      # Defaults
      self[:database] = 'sqlite:////' + File.join(
        File.expand_path(CortexReaver::HOME_DIR),
       'cortex_reaver.db'
      )
      self[:root] = CortexReaver::HOME_DIR
      self[:log_root] = File.join(CortexReaver::HOME_DIR, 'log')
      self[:plugin_root] = File.join(CortexReaver::HOME_DIR, 'plugins')
      self[:mode] = :production
      self[:adapter] = 'thin'
      self[:cache] = :memory
      self[:host] = nil
      self[:port] = 7000
      self[:plugins] = []

      self[:site] = {
        :name => 'Cortex Reaver',
        :description => "Stalks the dark corridors of this station, converting humans to Shodan's perfection.",
        :keywords => 'Cortex Reaver, blog',
        :author => 'Shodan'
      }

      # Load from file
      if File.exists? file
        begin
          self.merge!(YAML.load(File.read(file)))
        rescue => e
          raise RuntimeError.new("unable to load local configuration file #{file}: (#{e.message})")
        end
      end

      # Pidfile
      self[:pidfile] ||= File.join(CortexReaver::HOME_DIR, "cortex_reaver_#{self[:host] ? self[:host].to_s + '_' : ''}#{self[:port]}.pid")

      # Daemon mode
      self[:daemon] ||= true if self[:mode] == :production

      # Compile views
      self[:compile_views] ||= true if self[:mode] == :production
    end
    
    def public_root
      if self[:root]
        File.join(self[:root], 'public')
      end
    end

    def view_root
      if self[:root]
        File.join(self[:root], 'view')
      end
    end

    def layout_root
      if self[:root]
        File.join(self[:root], 'layout')
      end
    end
  end
end
