module Sequel
  module Plugins
    module Tags
      # Support for taggable models
      module ClassMethods
        # Returns all models with ANY of the following tags
        def tagged_with_any_of(tags)
          tagged_with(tags, false)
        end
        
        # Returns all models with ALL the following tags:
        def tagged_with(tags, all=true)
          # Find map between this model and tags, e.g. pages_tags
          map = [table_name.to_s, 'tags'].sort.join('_').to_sym
          
          # The name in the mapping table which points to us
          own_id = (table_name.to_s.singularize + '_id').to_sym
          
          # The tag IDs to search for
          ids = tags.map { |t| t.id }
          
          # Now filter this model, finding all ids which appear n times with
          # the same model_id in the mapping table, which has been filtered
          # to contain only rows with one of our interesting tags.
          #
          # Man, don't you wish MySQL had intersect?
          if all
            filter(:id =>
              CortexReaver.db[map].filter(:tag_id => ids).group(own_id).having(
                "count(*) = #{ids.size}"
              ).select(own_id)
            )
          else
            filter(:id => 
              CortexReaver.db[map].filter(:tag_id => ids).select(own_id)
            )
          end
        end
      end
   
      module InstanceMethods 
        # If tags have changed, make sure to update those tags' counts.
        def after_save
          return false if super == false

          if @added_tags
            @added_tags.each do |tag|
              tag.count += 1
              tag.save
            end
            @removed_tags.each do |tag|
              tag.count -= 1
              tag.save
            end
          end

          true
        end

        # Remove tags on deletion
        def before_destroy
          return false unless super

          tags.each do |tag|
            tag.count -= 1
            if tag.count == 0
              tag.destroy
            else
              tag.save
            end
          end
          remove_all_tags

          true
        end

        # Set tags from a string, or array of tags. Finds existing tags or
        # creates new ones. Also updates tag counts.
        def tags=(tags)
          if tags.kind_of? String
            tags = tags.squeeze(',').split(',').map do |title|
              title.strip!
              if title.blank?
                # Do nothing
                tag = nil
              else
                # Look up existing tag
                tag = CortexReaver::Tag[:title => title]
                # Or create new one
                tag ||= CortexReaver::Tag.create(:title => title, :name => CortexReaver::Tag.canonicalize(title))
                unless tag
                  # Everything failed
                  raise RuntimeError.new("couldn't find or create tag for #{title}")
                end
              end
              tag
            end
          end

          unless tags.respond_to? :each
            raise ArgumentError.new("Needed a string or Enumerable of Tags, got #{tags.class}")
          end

          # Get rid of empty tags
          tags.reject do |tag|
            tag.nil?
          end
          tags.uniq!

          # Find which tags to change. Their counts are updated by an after_save
          # callback.
          old_tags = self.tags
          @removed_tags = old_tags - tags
          @added_tags = tags - old_tags

          # Change own tags
          remove_all_tags
          tags.each do |tag|
            add_tag tag
          end
        end
      end
    end
  end
end
