module Ramaze
  module Helper
    # Adds an atom method to each controller it's included in, which 
    # lists that controller's recent elements by yielding a block with
    # each record and a builder object for the feed.
    #
    # Requires crud.
    module Feeds
      require 'builder'

      Helper::LOOKUP << self

      def self.included(base)
        base.instance_eval do
          def self.for_feed(&block)
            @for_feed_block = block
          end

          def self.for_feed_block
            @for_feed_block
          end
        end
      end

      def atom
        atom_builder
      end

      private

      def atom_builder(params = {:model_class => self.model_class})
        response['Content-Type'] = 'application/atom+xml'

        x = Builder::XmlMarkup.new(:indent => 2)
        x.instruct!

        # Get model class to work with
        model_class = params[:model_class]

        # Get recent items
        recent = params[:recent] || model_class.recent

        # Find update time
        updated = recent.first.updated_on.xmlschema

        x.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
          x.id = model_class.url
          x.title CortexReaver.config.name + ' - ' + model_class.to_s.demodulize.titleize
          # x.subtitle
          x.updated updated
          x.link :href => model_class.url
          x.link :href => model_class.atom_url, :rel => 'self'

          recent.all do |model|
            x.entry do
              x.id model.url
              x.title model.title
              x.published model.created_on.xmlschema
              x.updated model.updated_on.xmlschema
              x.link :href => model.url, :rel => 'alternate'

              x.author do
                x.name model.user.name

                if model.user.http
                  x.uri model.user.http
                end
              end

              # Any additional controller-specific info
              if self.class.for_feed_block
                self.class.for_feed_block.call(model, x)
              end
            end
          end
        end
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
