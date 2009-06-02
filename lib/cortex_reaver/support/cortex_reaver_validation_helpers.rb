module Sequel
  module Plugins
    # Extra validation helpers!
    module CortexReaverValidationHelpers
      module InstanceMethods
        # Checks to ensure att and att_confirmation are the same.
        def validates_confirmation(atts, opts={})
          validatable_attributes(atts, opts) { |a,v,m| (m || "does not match confirmation") unless v == self.send(a.to_s + '_confirmation') }
        end
      end
    end
  end
end
