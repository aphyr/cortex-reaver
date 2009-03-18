module Ramaze
  module Helper
    module Tags
      # Adds an AJAX-ified tag editor for a model.
      def live_tags_field(model, opts={:name => 'tags'})
        name = opts[:name]
        title = opts[:title] || name.to_s.titleize
        
        s = "<p><label for=\"#{name}\">#{title}</label>"
        s << "<input name=\"#{name}\" id=\"#{name}\" type=\"text\" class=\"acfb-input\" value=\"#{attr_h(tags_on(model, false))}\" />"
        s << "</p>"

        s << <<EOF

<script type="text/javascript">
/* <![CDATA[ */
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

