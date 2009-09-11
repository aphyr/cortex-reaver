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

      define :memcache,
        :desc => "Memcache options",
        :default => Construct.new

      memcache.define :servers,
        :desc => "Servers to use. An array of strings like 'host:port:weight'",
        :default => ['localhost']

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
      view.define :sidebar,
        :desc => "An array of sidebars: [path, view]. Path is matched against the current request path. * globs to any non-slash characters, ** globs to all characters. The view is a string referencing the view in view/sidebar/ to render.
        
For example, if you wanted to render view/sidebar/tweet.rhtml using the twitter plugin, but only on the main page, you could do:

  ['/', 'twitter']

Or to render a related entries box on all photograph pages...

  ['/photographs/show/*', 'related']

You can also just provide a regex for the path, in which case it is matched directly against path_info. For example, here's how I show some custom tags on /photographs and other photo index pages:

  [/^\/photographs(\/(page|tagged))?/, 'explore_photos']
  [/^\/journals(\/(page|tagged))?/, 'explore_journals']
",
        :default => [
          ['**', 'sections'],
          ['**', 'admin'],
          ['/', 'photographs']
        ]

      define :css,
        :desc => "An array of CSS files to load first, in order.",
        :default => []
      define :js,
        :desc => "An array of Javascript files to load first, in order.",
        :default => [
          'jquery.js',
          'jquery.color.js',
          'jquery.dimensions.js',
          'jquery.corners.min.js',
          'jquery.hotkeys-0.7.9.js',
          'cookie.js'
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
      return @earliest_content if @earliest_content

      ej = CortexReaver::Journal.dataset.min(:created_on)
      @earliest_content = DateTime.parse(
        [
          CortexReaver::Journal.dataset.min(:created_on),
          CortexReaver::Page.dataset.min(:created_on),
          CortexReaver::Photograph.dataset.min(:created_on),
          CortexReaver::Project.dataset.min(:created_on)
        ].compact.min.to_s
      )
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
