module Ramaze
  class MemcachedCache
    # I can't figure out a good way to specify the parameters Ramaze::Cache
    # uses when instantiating new caches, so I'm just going to override the
    # setup here. Innate hardcodes the app name as "pristine". :(
    def cache_setup(host, user, app, name)
      app = Ramaze.options.app.name
      @namespace = [host, user, app, name].compact.join('-')
      options = {:namespace => @namespace}.merge(OPTIONS)
      servers = options.delete(:servers)
      @store = ::MemCache.new(servers, options)
    end
  end
end
