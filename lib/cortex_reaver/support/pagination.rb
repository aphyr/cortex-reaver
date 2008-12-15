module CortexReaver
  module Model
    # Defines class-level accessors for page size, order attribute, etc.
    module Pagination
      DEFAULT_SIZE = 16
      DEFAULT_ORDER = 'created_on'
      DEFAULT_REVERSE = false

      def self.included(base)
        base.class_eval do
          class << self
            attr_accessor :page_size, :page_order, :page_reverse
          end

          @page_size ||= CortexReaver::Model::Pagination::DEFAULT_SIZE
          @page_order ||= CortexReaver::Model::Pagination::DEFAULT_ORDER
          @page_reverse ||= CortexReaver::Model::Pagination::DEFAULT_REVERSE
        end

        # Returns a paginated dataset at page number. Optionally, filters on
        # dataset instead of the whole model.
        def page(number, dataset = self.dataset)
          if reverse
            dataset = dataset.reverse
          end

          dataset.order(@order).paginate(number, @page_size)
        end
      end

      # Returns the page number for this model. Optionally, filters on dataset
      # rather than the whole model.
      def page_number(dataset = self.class.dataset)
        
      end
    end
  end
end
