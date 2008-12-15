module CortexReaver
  # Contains site-specific configuration information for a CortexReaver site.
  class Config < Hash
    # Pass a YAML file with configuration options. At a minimum, it should specify
    # database = {:proto, :username, :pasword, :host, :database}
    # or database = "sequel_connect_string"
    def initialize(file)
      # Defaults
      unless File.exist?(dir = File.join(Dir.pwd, 'public'))
        dir = File.join(CortexReaver::LIB_DIR, 'public')
      end
      self[:public_root] = dir

      unless File.exist?(dir = File.join(Dir.pwd, 'view'))
        dir = File.join(CortexReaver::LIB_DIR, 'view')
      end
      self[:view_root] = dir

      self[:adapter] = 'mongrel'
      self[:port] = 7000

      begin
        self.merge!(YAML.load(File.read(file)))
      rescue => e
        raise RuntimeError.new("unable to load local configuration file #{file}: (#{e.message})")
      end
    end
  end
end
