module CortexReaver
  class Page < Sequel::Model(:pages)
    include CortexReaver::Model::Timestamps
    include CortexReaver::Model::CachedRendering
    include CortexReaver::Model::Renderer
    include CortexReaver::Model::Canonical
    include CortexReaver::Model::Attachments
    include CortexReaver::Model::Comments
    include CortexReaver::Model::Tags
    include CortexReaver::Model::Sequenceable

    belongs_to :page, :class => 'CortexReaver::Page'
    has_many   :pages, :class => 'CortexReaver::Page'
    belongs_to :creator, :class => 'CortexReaver::User', :key => 'created_by'
    belongs_to :updater, :class => 'CortexReaver::User', :key => 'updated_by' 
    has_many   :comments, :class => 'CortexReaver::Comment'
    many_to_many :tags, :class => 'CortexReaver::Tag'

    # Top-level pages.
    subset :top, :page_id => nil

    validates do
      uniqueness_of :name
      presence_of   :name
      length_of     :name, :maximum => 255
      presence_of   :title
      length_of     :title, :maximum => 255

      each(:name, :tag => :url_conflict) do |object, attributes, value|
        if controller = Ramaze::Controller.at(object.url)
          object.errors['name'] << "conflicts with the #{controller}"
        end
      end
    end

    # Reserve names of controllers so we don't conflict.
    Ramaze::Global.mapping.keys.each do |path|
      path =~ /\/(.+)(\/|$)/
      self.reserved_canonical_names << $1 if $1
    end

    # Also reserve everything in the public directory, as a courtesy.
    #
    # I can't stop you from shooting yourself in the foot, but this will help
    # you aim higher. :)
    self.reserved_canonical_names += Dir.entries(CortexReaver.config[:public_root]) - ['..', '.']

    # Use standard cached renderer
    render :body

    def render(text)
      bluecloth(
        macro(
          erubis_filter(
            syntax_highlight(
              text
            )
          )
        ), false, false
      )
    end

    # Canonicalize only in the context of our parent's namespace.
    # Arguments:
    # - A proper canonical name to check for conflicts with
    # - :id => An optional id to ignore conflicts with
    # - :page_id => A parent page_id to use as the namespace for conflict checking.
    def self.similar_canonical_names(proper, opts={})
      id = opts[:id]
      page_id = opts[:page_id]

      similar = []
      # Get parent page id for the current context.
      if filter(canonical_name_attr => proper, :page_id => page_id).exclude(:id => id).limit(1).count > 0
        # This name already exists, and it's not ours.
        similar << proper
        similar += filter(canonical_name_attr.like(/^#{proper}\-[0-9]+$/)).filter(:page_id => page_id).map(canonical_name_attr)
      end
      similar
    end
    
    # get('foo', 'bar', 'baz')
    # get('foo/bar/baz')
    def self.get(ids)
      unless ids.is_a? Array
        ids = ids.split('/')
      end

      # Look up ids by nested names.
      ids.inject(nil) do |page, name|
        puts "Searching for #{name} in #{page.inspect}"
        parent_id = page ? page.id : nil
        self[:page_id => parent_id, :name => name]
      end
    end

    def self.url
      '/'
    end

    def self.recent
      reverse_order(:updated_on).limit(16)
    end

    def atom_url
      '/pages/atom/' + id.to_s
    end

    def url
      if page
        page.url + '/' + name
      else
        '/' + name
      end
    end

    def to_s
      title || name
    end

    # Returns true if this page is located underneath another page.
    # within?(self) => true.
    def within?(other)
      if parent = page
        self == other or parent.within?(other)
      else
        self == other
      end
    end

    # Create a default page if none exists.
    if table_exists? and Page.count == 0
      Page.new(
        :name => 'about',
        :title => 'About Cortex Reaver',
        :body => <<EOF
<p>Cortex Reaver is a blog engine designed for managing photographs, projects,
journal entries, and more, with support for tags and comments. Cortex
Reaver is written in <a href="http://ruby-lang.org">Ruby</a> using <a
href="http://ramaze.net">Ramaze</a>, uses the <a
href="http://sequel.rubyforge.org/">Sequel</a> database toolkit and the <a
href="http://www.kuwata-lab.com/erubis/">Erubis</a> templating engine, and
makes use of the <a href="http://jquery.com">JQuery</a> JavaScript framework.
The author is <a href="http://aphyr.com">Aphyr</a>.</p>
EOF
      ).save
    end
  end
end
