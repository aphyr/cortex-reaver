module CortexReaver
  class Journal < Sequel::Model(:journals)
    include CortexReaver::Model::Timestamps
    include CortexReaver::Model::CachedRendering
    include CortexReaver::Model::Renderer
    include CortexReaver::Model::Canonical
    include CortexReaver::Model::Attachments
    include CortexReaver::Model::Comments
    include CortexReaver::Model::Tags
    include CortexReaver::Model::Sequenceable

    many_to_many :tags, :class => 'CortexReaver::Tag'
    belongs_to :creator, :class => 'CortexReaver::User', :key => 'created_by'
    belongs_to :updater, :class => 'CortexReaver::User', :key => 'updated_by'
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
      reverse_order(:created_on).limit(16)
    end

    def self.url
      '/journals'
    end

    def self.atom_url
      '/journals/atom'
    end

    def atom_url
      '/journals/atom/' + name
    end

    def url
      '/journals/show/' + name
    end

    def to_s
      title || name
    end
  end
end
