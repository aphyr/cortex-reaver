module CortexReaver
  # Contains site-specific configuration information for a CortexReaver site.
  class Config < Construct
    def initialize(*args)
      super *args

      # Defaults
      define :root,
        :desc => 'The local directory where CortexReaver runs.',
        :default => CortexReaver::HOME_DIR
      define :log_root,
        :desc => 'Directory where logs are stored.',
        :default => File.join(root, 'log')
      define :layout_root,
        :desc => 'Local directory where layouts are found.',
        :default => File.join(root, 'layout')
      define :plugin_root,
        :desc => 'Local directory where plugins are found.',
        :default => File.join(root, 'plugins')
      define :public_root,
        :desc => 'Local directory where public files are found.',
        :default => File.join(root, 'public')
      define :view_root,
        :desc => 'Local directory where views are found.',
        :default => File.join(root, 'view')


      define :database, :default => Construct.new
      database.define :adapter,
        :desc => 'Database adapter',
        :default => 'sqlite'
      database.define :username,
        :desc => 'Username',
        :default => nil
      database.define :password,
        :desc => 'Database password',
        :default => nil
      database.define :host,
        :desc => 'Host to connect to for the database.',
        :default => nil
      database.define :port,
        :desc => 'Database port',
        :default => nil
      database.define :database,
        :desc => 'The database on the server to connect to.',
        :default => '/' + File.expand_path(File.join(root, 'cortex_reaver.db'))
      database.define :string,
        :desc => 'A Sequel connection string. If present, overrides the other DB fields.',
        :default => nil

      def database.str
        if string
          string
        else
          str = ''
          str << adapter + '://' if adapter
          str << username if username
          str << ':' + password if username and password
          str << '@' if username or password
          str << host if host
          str << ':' + port if host and port
          str << '/'
          str << database if database
        end
      end


      define :mode,
        :desc => 'Development or production mode.',
        :default => :production
      define :adapter,
        :desc => 'The web server adapter used for Cortex Reaver.',
        :default => 'thin'
      define :cache,
        :desc => 'The caching system used. One of :memory or :memcache',
        :default => :memory
      define :host,
        :desc => 'Host address to bind to.',
        :default => nil
      define :port,
        :desc => 'Port to bind to.',
        :default => 7000

      define :plugins,
        :desc => 'Plugins configuration space.',
        :default => Construct.new
      plugins.define :enabled, 
        :desc => 'Plugin names to enable.',
        :default => []

      define :site,
        :desc => 'Site configuration options',
        :default => Construct.new
      site.define :url,
        :desc => 'The URL base for the web site. No trailing /.',
        :default => 'http://localhost'
      site.define :name,
        :desc => 'The name of this web site. Used in titles, metadata, etc.',
        :default => 'Cortex Reaver'
      site.define :description,
        :desc => 'A brief description of this site.',
        :default => "Stalks the dark corridors of this station, converting humans to Shodan's perfection."
      site.define :keywords,
        :desc => 'Site keywords',
        :default => 'Cortex Reaver, blog'
      site.define :author,
        :desc => 'The primary author of this site, used in copyright & metadata.',
        :default => 'Shodan'

      define :pidfile,
        :desc => 'Filename which stores the process ID of Cortex Reaver.',
        :default => File.join(root, "cortex_reaver_#{host ? host.to_s + '_' : ''}#{port}.pid")
      define :daemon,
        :desc => "Whether to daemonize. Enabled by default in production mode."
      define :compile_views,
        :desc => 'Whether to compile views. Enabled by default in production.'

      define :view, 
        :desc => "Configuration options for content display.",
        :default => Construct.new
      view.define :sections,
        :desc => "A list of top-level sections for navigation. First is the human-readable name, and second is the URI for the link.",
        :default => [
          ['Journals', '/journals'],
          ['Photographs', '/photographs'],
          ['Projects', '/projects'],
          ['Tags', '/tags'],
          ['Comments', '/comments'],
          ['About', '/about']
        ]

    end

    def compile_views
      if include? :compile_views
        self[:compile_views]
      else
        mode == :production
      end
    end

    def daemon
      if include? :daemon
        self[:daemon]
      else
        mode == :production
      end
    end

    # Returns the earliest thing in the CortexReaver DB, for copyright.
    def earliest_content
      @earliest_content ||= DateTime.parse([
        CortexReaver::Journal.dataset.min(:created_on),
        CortexReaver::Page.dataset.min(:created_on),
        CortexReaver::Photograph.dataset.min(:created_on),
        CortexReaver::Project.dataset.min(:created_on)
      ].min)
    end

    # Saves self to disk
    def save
      Ramaze::Log.info "Saving config #{to_yaml}"
      File.open(CortexReaver.config_file, 'w') do |file|
        file.write to_yaml
      end
    end
  end
end
