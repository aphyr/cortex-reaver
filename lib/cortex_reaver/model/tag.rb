module CortexReaver
  class Tag < Sequel::Model(:tags)
    plugin :canonical

    many_to_many :photographs, :class => 'CortexReaver::Photograph'
    many_to_many :journals, :class => 'CortexReaver::Journal'
    many_to_many :projects, :class => 'CortexReaver::Project'
    many_to_many :pages, :class => 'CortexReaver::Page'

    subset :unused, :count => 0

    validates do
      uniqueness_of :name
      presence_of :name
      length_of :name, :maximum => 255 
      presence_of :title
      length_of :title, :maximum => 255
    end

    # When we delete a tag, ensure nothing else is linked to it.
    def before_destroy
      return false unless super
      
      remove_all_photographs
      remove_all_journals
      remove_all_projects
      remove_all_pages

      true
    end

    # Autocompletes a tag. Returns an array of matching candidates
    def self.autocomplete(string)
      filter(:title.like(/^#{string}/i)).limit(6).map(:title)
    end

    # Recalculates the number of children on each tag, and saves the updated values.
    def self.refresh_counts
      updated = []
      order(:title).all.each do |tag|
        result = tag.refresh_count
        updated << [tag, result] if result
      end
      updated
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

    # Recalculates the number of children on this tag, and saves the update value. Returns [old_count, new_count] if changed.
    def refresh_count
      # Find counts
      old_count = self[:count]
      self[:count] = photographs_dataset.count + 
        journals_dataset.count +
        pages_dataset.count + 
        projects_dataset.count
      
      # Save and return
      changed = changed_columns.include? :count
      self.save

      if changed
        [old_count, self[:count]]
      else
        nil
      end
    end

    def url
      '/tags/show/' + name
    end

    def to_s
      title || name
    end
  end
end
