module Ramaze
  module Helper
    # Provides programmatic sidebar boxes
    module Sidebar
      # Renders the sidebar
      def sidebar
        sidebar = ''
        CortexReaver.config.view.sidebar.each do |path, view|
          if path_matches? path
            sidebar << CortexReaver::MainController.render_view('sidebar/' + view)
          end
        end
        sidebar
      end

      # True if the given glob matches our request path.
      def path_matches?(path)
        case path
        when String
          # Convert string to regex.
          pattern = path.gsub(/\*(\*)?/) do |match|
            if match[1]
              '.*'
            else
              '[^\/]*'
            end
          end

          if Regexp.new("^#{pattern}$").match request.path
            true
          else
            false
          end
        when Regexp
          if path.match request.path
            true
          else
            false
          end
        end
      end
    end
  end
end
