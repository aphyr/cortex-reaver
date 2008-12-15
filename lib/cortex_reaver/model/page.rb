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

    belongs_to :user, :class => 'CortexReaver::User'
    has_many :comments, :class => 'CortexReaver::Comment'
    many_to_many :tags, :class => 'CortexReaver::Tag'

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
    # I can't stop you from shooting yourself in the foot, but this will help you
    # aim higher. :)
    self.reserved_canonical_names += Dir.entries(CortexReaver.config[:public_root]) - ['..', '.']

    # Use standard cached renderer
    render :body

    def self.get(id)
      self[:name => id] || self[id]
    end

    def self.url
      '/'
    end

    def self.recent
      reverse_order(:updated_on).limit(16)
    end

    def atom_url
      '/pages/atom/' + name
    end

    def url
      '/' + name
    end

    def to_s
      title || name
    end

    # Create a default page if none exists.
    if table_exists? and Page.count == 0
      Page.new(
        :name => 'about',
        :title => 'About Cortex Reaver',
        :body => <<EOF
<p>Cortex Reaver is a blog engine designed for managing photographs, projects,
journal entries, and more, with support for tags, comments, and ratings. Cortex
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
