module Ramaze
  module Helper
    # Adds an atom method to each controller it's included in, which 
    # lists that controller's recent elements by yielding a block with
    # each record and a builder object for the feed.
    #
    # Requires crud. Will attempt to cache feeds if the cache helper is available.
    module Feeds
      require 'libxml'

      Helper::LOOKUP << self

      def self.included(base)
        base.instance_eval do
          def self.for_feed(&block)
            @for_feed_block = block
          end

          def self.for_feed_block
            @for_feed_block
          end

          # Cache feeds
          if base.respond_to? :cache_action
            base.cache_action(:method => :atom, :ttl => 300)
          end
        end
      end

      def atom
        atom_builder
      end

      private

      def atom_builder(params = {:model_class => self.class.const_get('MODEL')})
        response['Content-Type'] = 'application/atom+xml'

        # Get model class to work with
        model_class = params[:model_class]

        # Get recent items
        recent = params[:recent] || model_class.recent

        # Find update time
        if first = recent.first
          updated = first.updated_on.xmlschema
        else
          updated = Time.now.xmlschema
        end

        # Doc
        doc = LibXML::XML::Document.new
        doc.root = (root = LibXML::XML::Node.new('feed'))
        root['xmlns'] = 'http://www.w3.org/2005/Atom'

        # Global opts
        root << (id = LibXML::XML::Node.new('id'))
        id << CortexReaver.config.site.url.to_s

        root << (title = LibXML::XML::Node.new('title'))
        title << "#{CortexReaver.config.site.name} - #{model_class.to_s.demodulize.titleize}"

        root << (updated_node = LibXML::XML::Node.new('updated'))
        updated_node << updated.to_s

        root << (link = LibXML::XML::Node.new('link'))
        link['href'] = full_url('/')

        root << (link = LibXML::XML::Node.new('link'))
        link['href'] = full_url(model_class.atom_url)
        link['rel'] = 'self'

        recent.all do |model|
          root << (entry = LibXML::XML::Node.new('entry'))
          
          entry << (id = LibXML::XML::Node.new('id'))
          id << full_url(model.url)

          entry << (title = LibXML::XML::Node.new('title'))
          title << model.title.to_s

          entry << (published = LibXML::XML::Node.new('published'))
          published << model.created_on.xmlschema

          entry << (updated = LibXML::XML::Node.new('updated'))
          updated << model.updated_on.xmlschema

          entry << (link = LibXML::XML::Node.new('link'))
          link['href'] = full_url(model.url)
          link['rel'] = 'alternate'

          entry << (author = LibXML::XML::Node.new('author'))
          author << (name = LibXML::XML::Node.new('name'))
          name << model.creator.name.to_s

          if model.creator.http
            author << (uri = LibXML::XML::Node.new('uri'))
            uri << model.creator.http.to_s
          end

          # Any additional controller-specific info
          if self.class.for_feed_block
            self.class.for_feed_block.call(model, entry)
          end
        end

        doc
      end

      def feeds
        @feeds ||= {}
      end

      def feed(title, href)
        feeds[title] = href
      end
    end
  end
end
