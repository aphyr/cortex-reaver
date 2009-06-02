module CortexReaver
  class Project < Sequel::Model(:projects)
    plugin :timestamps
    plugin :cached_rendering
    plugin :canonical
    plugin :attachments
    plugin :comments
    plugin :tags
    plugin :sequenceable
    plugin :viewable
    include CortexReaver::Model::Renderer

    many_to_many :tags, :class => 'CortexReaver::Tag'
    many_to_one :creator, :class => 'CortexReaver::User', :key => 'created_by'
    many_to_one :updater, :class => 'CortexReaver::User', :key => 'updated_by'
    one_to_many :comments, :class => 'CortexReaver::Comment'

    validates do
      uniqueness_of :name
      presence_of :name
      length_of :name, :maximum => 255
      presence_of :title
    end

    render :body

    def self.atom_url
      '/projects/atom'
    end

    def self.get(id)
      self[:name => id] || self[id]
    end

    def self.recent
      reverse_order(:updated_on).limit(16)
    end

    def self.url
      '/projects'
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
