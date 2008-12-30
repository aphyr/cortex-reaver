module CortexReaver
  module Model
    # Some common rendering methods, wrapped up for your convenience. Use in
    # your model with something like:
    #
    # render :body, :with => :render_comment
    #
    # See CortexReaver::Model::CachedRendering for more details.
    module Renderer

      require 'bluecloth'
      require 'hpricot'
      require 'coderay'

      # Elements to allow in sanitized HTML.
      ELEMENTS = [
        'a', 'b', 'blockquote', 'br', 'code', 'dd', 'dl', 'dt', 'em', 'i', 'li',
        'ol', 'p', 'pre', 'small', 'strike', 'strong', 'sub', 'sup', 'u', 'ul'
      ]
   
      # Attributes to allow in sanitized HTML elements.
      ATTRIBUTES = {
        'a' => ['href', 'title'],
        'pre' => ['class']
      }
      
      # Attributes to add to sanitized HTML elements.
      ADD_ATTRIBUTES = {
        'a' => {'rel' => 'nofollow'}
      }
   
      # Attributes that should be checked for valid protocols.
      PROTOCOL_ATTRIBUTES = {'a' => ['href']}
   
      # Valid protocols.
      PROTOCOLS = ['ftp', 'http', 'https', 'mailto']

      
      # Renders plain text and html to html. If parse_code isn't true, only
      # runs bluecloth on text *outside* any <code>...</code> blocks.
      def bluecloth(text, parse_code = true)
        return text if text.nil?

        if parse_code
          return BlueCloth::new(text).to_html
        end

        text = text.dup
        out = ''
        level = 0
        until text.empty? do
          if level < 1
            # Find start of code block
            j = text.index('<code>') || text.length
            j -= 1 if j != 0
            level += 1
           
            if j != 0
              # Convert to bluecloth
              blue = BlueCloth::New(text[0..j]).to_html
              # Increment headings by two (h1 is site header, h2 is page header)
              blue.gsub!(/<(\/)?h(\d)>/) { |match| "<#{$1}h#{$2.to_i + 2}>" }
              out << blue
            end
          else
            # Find end of code block
            j = text.index('</code>') || text.length
            level -= 1
            j += 6

            # Output as is
            out << text[0..j]
          end

          # Excise parsed string
          text.slice! 0..j unless j == 0
        end

        out
      end

      # Replace <% and %> to prevent Erubis injection.
      def erubis_filter(text)
        return text if text.nil?
        
        t = text.dup
        t.gsub!('<%', '&lt;%')
        t.gsub!('%>', '%&rt;')
        t
      end

      # Macro substitutions
      #
      # Expands [[type:resource][name]] macros. Right now, resource is just an
      # attachment.
      #
      # Included types are:
      #
      # url: returns the URL to an attachment
      # image: returns an image tag
      # link: returns a link to an attachment
      #
      # The default action is a link, so
      #
      # [[foo.jpg]] => <a href="/data/.../foo.jpg">foo.jpg</a>
      def macro(text)
        return text if text.nil?

        copy = text.dup

        # Links
        # 
        # Example                         [[image:foo.png][name]]
        # 1. the link type prefix         image:
        # 2. the link type, sans-colon    image
        # 3. the link itself              foo.png
        # 4. the second half of the link  [name]
        # 5. the name                     name 
       copy.gsub!(/\[\[(([^\]]+):)?([^\]]+)(\]\[([^\]]+))?\]\]/) do |match|
          prefix = $2
          path = $3
          name = $5

          # Find the link target
          target = attachment(path)

          if target.exists?
            # Name of the link
            name ||= path

            # Create link to this target
            case prefix
            when 'image'
              # Create an inline image
              "<img src=\"#{target.public_path}\" alt=\"#{name.gsub('"', '&quot;')}\" title=\"#{name.gsub('"', '&quot')}\" />"
            when 'url'
              # Create a URL
              target.public_path
            else
              # Create a full link
              "<a href=\"#{target.public_path}\">#{Rack::Utils.escape_html(name).gsub(/#([{@$]@?)/, '&#35;\1')}</a>"
            end
          else
            # Don't create a link
            match
          end
        end
       
        copy
      end

      def syntax_highlight(text)
        return text if text.nil?

        text.gsub(/<cr:code\s.*?(lang="(.*?)").*?>(.*?)<\/cr:code>/m) do |match|
          lang = $2
          code = $3

          # Replace entities
          code.gsub!('&', '&quot;')

          unless lang.empty?
            # Parse with CodeRay.
            code = '<div class="code"><code>' + CodeRay.scan(code, lang.to_sym).html.strip + '</code></div>'
          end

          # Using white-space: pre is a nice option, but I haven't figured out
          # how to make it work with fluid layouts. So, I'm going with line
          # wrapping and explicit HTML entities; since we're already marking
          # up the code for syntax, might as well go all the way. Plus, 
          # this still pastes cleanly, but displays like a terminal.
          code.gsub!("\n", '<br />')
          code.gsub!(/( {2})/) { |match| '&nbsp;' * $1.length }
        end
      end

      # Stolen wholesale from Ryan's Thoth (http://github.com/rgrove/thoth/)
      # Who adapted it from http://rid.onkulo.us/archives/14-sanitizing-html-with-ruby-and-hpricot
      def sanitize_html(html)
        return html if html.nil?

        h = Hpricot(html)
  
        h.search('*').each do |el|
          if el.elem?
            tag = el.name.downcase
   
            if ELEMENTS.include?(tag)
              if ATTRIBUTES.has_key?(tag)
                # Delete any attribute that isn't in the whitelist for this
                # particular element.
                el.raw_attributes.delete_if do |key, val|
                  !ATTRIBUTES[tag].include?(key.downcase)
                end
   
                # Check applicable attributes for valid protocols.
                if PROTOCOL_ATTRIBUTES.has_key?(tag)
                  el.raw_attributes.delete_if do |key, val|
                    PROTOCOL_ATTRIBUTES[tag].include?(key.downcase) &&
                        (!(val.downcase =~ /^([^:]+)\:/) || !PROTOCOLS.include?($1))
                  end
                end
              else
                # Delete all attributes from elements with no whitelisted
                # attributes.
                el.raw_attributes = {}
              end
   
              # Add required attributes.
              if ADD_ATTRIBUTES.has_key?(tag)
                el.raw_attributes.merge!(ADD_ATTRIBUTES[tag])
              end
            else
              # Delete any element that isn't in the whitelist.
              el.parent.replace_child(el, el.children)
            end
          elsif el.comment?
            # Delete all comments, since it's possible to make IE execute JS
            # within conditional comments.
            el.swap('')
          end
        end
   
        h.to_s
      end

      # Default renderer
      def render(text)
        bluecloth(
          macro(
            erubis_filter(
              syntax_highlight(
                text
              )
            )
          ), false
        ) # (((Feeling) LISPish yet)?)
      end

      # Comments render
      def render_comment(text)
        bluecloth(
          erubis_filter(
            sanitize_html(
              text
            )
          )
        )
      end
    end
  end
end
