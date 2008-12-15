module Ramaze
  module Helper
    # Provides some error pages
    module Error
      def error_404
        respond 'Page not found', 404
      end

      def error_403
        respond 'Forbidden', 403
      end
    end
  end
end
