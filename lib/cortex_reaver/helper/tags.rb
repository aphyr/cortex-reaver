module Ramaze
  module Helper
    module Tags
      Helper::LOOKUP << self

      # Finds models with a given tag.
      def tagged(tags)
        tags = tags.split(',').map! do |tag|
          CortexReaver::Tag.get(tag.gsub(/[^-_\w]+/, '').strip)
        end

        @title = "#{model_class.to_s.demodulize.pluralize.titleize}: #{tags.join(', ')}"
        @models = model_class.tagged_with(tags)
        set_plural_model_var @models

        if user.can_create? model_class.new
          workflow "New #{model_class.to_s.demodulize}", rs(:new)
        end

        render_view(:list)
      end

      private
      # Adds an AJAX-ified tag editor for a model.
      def live_tags_field(model, opts={:name => 'tags'})
        name = opts[:name]
        title = opts[:title] || name.to_s.titleize
        
        s = "<p><label for=\"#{name}\">#{title}</label>\n"
        s << "<ul id=\"#{name}-holder\" class=\"acfb-holder\">\n"
        s << "<input name=\"#{name}\" id=\"#{name}\" type=\"text\" class=\"acfb-input\" value=\"#{attr_h(tags_on(model, false))}\" />"
        s << "</ul></p>"

        s << <<EOF
<script type="text/javascript">
    /* <![CDATA[ */
    $(document).ready(function() {
      $("##{name}-holder").autoCompletefb({
        urlLookup:'/tags/autocomplete',
        acOptions:{extraParams:{id:'title'}}
      });
    });
    /* ]]> */
  </script>
EOF
      end

      # Returns an html list of tags on a model that supports #tags.
      def tags_on(model, html=true)
        begin
          if html
            #t = '<img src="/images/tag.gif" alt="Tags" />'
            t = '<ul class="tags">'
            model.tags.each do |tag|
              t << "<li><a href=\"#{tag.url}\">#{tag.title}</a></li>"
            end
            t << '</ul>'
          else
            t = model.tags.map{ |t| t.title }.join(', ')
          end
        rescue
          # HACK: This is probably only going to break because a blank model is
          # missing a primary key or something like that. Since we call this
          # method SO much (and because that specific error is not subclassed
          # by Sequel) no custom error handling here.
          ''
        end
      end
    end
  end
end

