module Ramaze
  module Helper
    # Provides workflow links on a per-section basis
    module Workflow
      def workflows
        @workflows
      end

      def workflow(name, href, *classes)
        @workflows ||= []
        @workflows << [name, href, classes]
      end
    end
  end
end
