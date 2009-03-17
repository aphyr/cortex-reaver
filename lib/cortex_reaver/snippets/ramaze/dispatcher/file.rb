module Ramaze
  class Dispatcher
 
    # Monkeypatch to add support for multiple public_roots.
    # Stolen from Thoth :)
    class File
      class << self
        def in_public?(path)
          path = expand(path)
 
          @expanded ||= {
            :default => expand(Ramaze::Global.public_root),
            :custom => expand(CortexReaver.config[:public_root])
          }
 
          path.start_with?(@expanded[:default]) ||
              path.start_with?(@expanded[:custom])
        end
 
        def resolve_path(path)
          joined = ::File.join(CortexReaver.config[:public_root], path)
 
          unless ::File.exist?(joined)
            joined = ::File.join(Ramaze::Global.public_root, path)
          end
 
          if ::File.directory?(joined)
            Dir[::File.join(joined, "{#{INDICES.join(',')}}")].first || joined
          else
            joined
          end
        end
      end
    end
 
  end
end
