module CortexReaver
  module Model
    # Supports canonical, url-safe identifiers for records, inferred from other
    # fields.
    module Canonical

      # The canonical name attribute
      CANONICAL_NAME_ATTR = :name
      # The attribute we infer the canonical name from, if not set.
      CANONICAL_INFERENCE_ATTR = :title

      def self.included(base)
        base.class_eval do
          # Canonical names which cannot be reserved.
          def self.reserved_canonical_names
            @reserved_canonical_names ||= []
          end

          def self.reserved_canonical_names=(names)
            @reserved_canonical_names = names
          end

          # Canonicalize a string. Optionally, ignore conflicts with the record
          # with id.
          def self.canonicalize(string, id = nil)
            # Lower case, remove special chars, and replace with hyphens.
            proper = string.downcase.gsub(/[^a-z0-9_]/, '-').squeeze('-')[0..250].sub(/-$/, '')

            # If proper is blank, just return it at this point.
            if proper.blank?
              return proper
            end

            # Numeric suffix to append
            suffix = nil

            if proper != filter(:id => id).map(canonical_name_attr).first
              # We don't already have this name.

              similar = []

              if filter(canonical_name_attr => proper).limit(1).count > 0
                similar << proper
                # This name already exists, and it's not ours!
                similar += filter(canonical_name_attr.like(/^#{proper}\-[0-9]+$/)).map(canonical_name_attr)
              end

              # Check for reserved names
              reserved_canonical_names.each do |name|
                if name =~ /^#{proper}(-\d+)?$/
                  similar << name
                end
              end

              # Find possible conflicting names from actions on this model's controller.
#              if self.respond_to? :url and controller = Ramaze::Controller.at(self.url)
#                similar += controller.action_methods.select do |action|
#                  action =~ /^#{proper}(-\d+)?$/
#                end
#              end

              # Extract numeric suffices
              suffices = {}
              similar.each do |name|
                suffices[name[/\d$/].to_i] = true
              end

              # Compute suffix
              unless suffices.empty?
                i = 1
                while suffices.include? i
                  i += 1
                end
                suffix = i
              end
            end

            if suffix
              proper + '-' + suffix.to_s
            else
              proper
            end
          end

          # Sets the attribute we infer the canonical name from to attr, or
          # gets that attr if nil.
          def self.canonical_inference_attr(attr = nil)
            if attr
              @canonical_inference_attr = attr.to_sym
            else
              @canonical_inference_attr || CANONICAL_INFERENCE_ATTR
            end
          end

          # Sets the canonical name attribute to attr. Returns it if nil.
          def self.canonical_name_attr(attr = nil)
            if attr
             @canonical_name_attr = attr.to_sym
            else
              @canonical_name_attr || CANONICAL_NAME_ATTR
            end
          end
        end
      end
    end
  end
end
