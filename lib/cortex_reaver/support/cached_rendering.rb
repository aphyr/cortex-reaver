module CortexReaver
  module Model

    # On save, calls a special rendering method on configured attributes, and
    # saves the results to their cache.
    module CachedRendering
      require 'ostruct'

      def self.included(base)
        base.class_eval do
          # Before save, render all changed caching fields
          before_save(:render_to_cache) do
            # Get changed fields to render
            if new?
              changed = columns.map { |c| c.to_sym }
            else
              changed = changed_columns.map { |c| c.to_sym }
            end
            fields = render_fields.select do |k, v|
              changed.include? k.to_sym
            end
            
            fields.each do |name, field|
              # Render and cache
              self[field.to] = self.send(field.with, self[name])
            end
          end

          # Refreshes all records with cached fields.
          def self.refresh_render_caches
            # TODO: inefficient, but Model.each breaks Sequel in validation
            # "commands out of sync"
            all.each do |record|
              # Mark all caching columns as changed, so the before_save hook
              # processes them.
              record.skip_timestamp_update = true
              render_fields.keys.each do |column|
                record.changed_columns << column
              end
              record.save
            end
            nil
          end

          # Assigns a field to cache
          #
          # render :body, :with => 'wikify', :to => 'cached_body'
          #
          # ... calls #wikify on the value of self.body, and stores the result
          # in self.cached_body. :to defaults to the field name with _cache
          # appended. :with defaults to :render.
          def self.render(field, params = {})
            # Assign parameters
            params = {
              :to => (field.to_s + '_cache').to_sym,
              :with => :render
            }.merge!(params)
           
            # Store field 
            render_fields[field] = OpenStruct.new(params)
          end

          def self.render_fields
            @render_fields ||= {}
          end
        end
      end

      # Default renderer
      def render(value)
        value  
      end

      def render_fields
        self.class.render_fields
      end
    end
  end
end
