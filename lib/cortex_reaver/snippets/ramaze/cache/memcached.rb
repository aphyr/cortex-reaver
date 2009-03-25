module Ramaze
  class MemcachedCache
    # I can't figure out a good way to specify the parameters Ramaze::Cache uses when
    # instantiating new caches, so I'm just going to override the constructor here.
    def initialize(host = 'localhost', port = '11211', namespace = Global.runner)
      namespace = 'cortex-reaver:' + CortexReaver.config_file
      namespace = Digest::SHA1.hexdigest(namespace)[0..16]
      @cache = MemCache.new(["#{host}:#{port}"], :namespace => namespace, :multithread => true)
    end
  end
end
