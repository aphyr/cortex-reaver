# A little no-op cache
module CortexReaver
  class Cache
    class Noop
      include Innate::Cache::API
      def cache_clear; end

      def cached_delete(key, *keys)
        nil
      end
      
      def cache_fetch(key, default = nil)
        default
      end

      def cache_setup(host, user, app, cache); end
    
      def cache_store(key, value, options = {})
        value
      end
    end
  end
end
