module CortexReaver
  # Contains site-specific configuration information for a CortexReaver site.
  class Config < Hash
    # Pass a YAML file with configuration options. At a minimum, it should specify
    # :database = {:proto, :username, :pasword, :host, :database}
    # or :database = "sequel_connect_string"
    #
    # :public_root - The directory public files are hosted from. Defaults to
    #                HOME_DIR/public.
    # :view_root   - The directory containing erubis view templates. Defaults to
    #                Cortex Reaver's builtin templates.
    # :log_root    - The directory that Cortex Reaver should log to. Defaults to
    #                HOME_DIR/log. If nil, file logging disabled.
    # :mode        - Cortex Reaver mode: either :development or :production
    # :daemon      - Whether to daemonize or not. Defaults to :true if :mode
    #                is :production, otherwise nil.
    # :adapter     - The Ramaze adapter name (default 'mongrel')
    # :host        - Host to bind to 
    # :port        - Port to bind to (default 7000)
    # :pidfile     - Process ID file for this server. Defaults to 
    #                HOME_DIR/cortex_reaver_<host>_<port>.pid
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
      self[:public_root] = File.join(CortexReaver::HOME_DIR, 'public')
      self[:view_root] = File.join(CortexReaver::LIB_DIR, 'view')
      self[:log_root] = File.join(CortexReaver::HOME_DIR, 'log')
      self[:mode] = :production
      self[:adapter] = 'mongrel'
      self[:host] = nil
      self[:port] = 7000

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
    end
  end
end
