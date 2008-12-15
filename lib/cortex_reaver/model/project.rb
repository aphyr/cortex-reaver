module CortexReaver
  class Project < Sequel::Model(:projects)
    def self.url
      '/projects'
    end

    include CortexReaver::Model::Timestamps
    include CortexReaver::Model::CachedRendering
    include CortexReaver::Model::Renderer
    include CortexReaver::Model::Canonical
    include CortexReaver::Model::Attachments
    include CortexReaver::Model::Comments
    include CortexReaver::Model::Tags
    include CortexReaver::Model::Sequenceable

    many_to_many :tags, :class => 'CortexReaver::Tag'
    belongs_to :user, :class => 'CortexReaver::User'
    has_many :comments, :class => 'CortexReaver::Comment'

    validates do
      uniqueness_of :name
      presence_of :name
      length_of :name, :maximum => 255
      presence_of :title
    end

    render :body

    def self.get(id)
      self[:name => id] || self[id]
    end

    def self.recent
      reverse_order(:updated_on).limit(16)
    end

    def atom_url
      '/projects/atom/' + name
    end

    def url
      '/projects/show/' + name
    end

    def to_s
      title || name
    end
  end
end
