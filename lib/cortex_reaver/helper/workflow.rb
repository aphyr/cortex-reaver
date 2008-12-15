module Ramaze
  module Helper
    # Provides workflow links on a per-section basis
    module Workflow
      def workflows
        @workflows
      end

      def workflow(name, href)
        @workflows ||= []
        @workflows << [name, href]
      end

      def workflowbox
        if @workflows
          b = '<div class="workflows">'
          b << '  <ul>'
          @workflows.each do |name, href|
            b << "    <li><a href=\"#{href}\">#{name}</a></li>"
          end
          b << '  </ul>'
          b << '</div>'
        end
      end
    end
  end
end
