module Sequel
  module Plugins
    # Supports updated_on and created_on behavior
    module Timestamps
      module InstanceMethods
        # Create
        def before_create
          return false if super == false

          unless skip_timestamp_update?
            self.created_on = Time.now
            self.updated_on = Time.now
          end

          true
        end

        # Update
        def before_update
          return false if super == false

          unless skip_timestamp_update?
            self.updated_on = Time.now
          end

          true
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
end
