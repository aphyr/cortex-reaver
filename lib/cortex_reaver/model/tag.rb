module CortexReaver
  class Tag < Sequel::Model(:tags)
    include CortexReaver::Model::Canonical

    many_to_many :photographs, :class => 'CortexReaver::Photograph'
    many_to_many :journals, :class => 'CortexReaver::Journal'
    many_to_many :projects, :class => 'CortexReaver::Project'
    many_to_many :pages, :class => 'CortexReaver::Page'

    validates do
      uniqueness_of :name
      presence_of :name
      length_of :name, :maximum => 255 
      presence_of :title
      length_of :title, :maximum => 255
    end

    # When we delete a tag, ensure nothing else is linked to it.
    before_destroy(:drop_associations) do
      remove_all_photographs
      remove_all_journals
      remove_all_projects
      remove_all_pages
    end

    # Autocompletes a tag. Returns an array of matching candidates
    def self.autocomplete(string)
      filter(:title.like(/^#{string}/i)).limit(6).map(:title)
    end

    # Recalculates the number of children on each tag, and saves the updated values.
    def self.refresh_counts
      all.each do |tag|
        tag.refresh_count
      end
    end

    def self.get(id)
      self[:name => id] || self[id]
    end

    def self.url
      '/tags'
    end

    def atom_url
      '/tags/atom/' + name
    end

    # Recalculates the number of children on this tag, and saves the update value.
    def refresh_count
      # Find counts
      self[:count] = photographs_dataset.count + 
        journals_dataset.count +
        pages_dataset.count + 
        projects_dataset.count
      
      # Save and return
      unless valid?
        p self
        p errors
        exit
      end
      self.save
      self[:count]
    end

    def url
      '/tags/show/' + name
    end

    def to_s
      title || name
    end
  end
end
