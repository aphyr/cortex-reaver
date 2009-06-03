module CortexReaver
  class Journal < Sequel::Model(:journals)
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


    render :body

    def self.atom_url
      '/journals/atom'
    end

    def self.get(id)
      self[:name => id] || self[id]
    end

    def self.recent
      reverse_order(:created_on).limit(16)
    end

    def self.url
      '/journals'
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

    def validate
      validates_unique :name
      validates_presence :name
      validates_max_length 255, :name
      validates_presence :title
    end
 
  end
end
