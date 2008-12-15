module CortexReaver
  module Model
    # Supports updated_on and created_on behavior
    module Timestamps
      def self.included(base)
        base.class_eval do
          # Create
          before_create(:init_timestamp) do
            unless skip_timestamp_update?
              self.created_on = Time.now
              self.updated_on = Time.now
            end
          end

          # Update
          before_update(:update_timestamp) do
            unless skip_timestamp_update?
              self.updated_on = Time.now
            end
          end
        end
      end

      def skip_timestamp_update=(boolean)
        @skip_timestamp_update = boolean
      end

      def skip_timestamp_update?
        @skip_timestamp_update
      end
    end
  end
end
