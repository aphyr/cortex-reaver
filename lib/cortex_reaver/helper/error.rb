module Ramaze
  module Helper
    # Provides some error pages
    module Error
      def error_404
        respond! 'Page not found', 404, "Content-Type" => "text/plain"
      end

      def error_403
        respond! 'Forbidden', 403, "Content-Type" => "text/plain"
      end
    end
  end
end
