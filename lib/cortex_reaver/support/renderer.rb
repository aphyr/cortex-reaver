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
      require 'sanitize'
      require "#{CortexReaver::LIB_DIR}/helper/pages"
      require "#{CortexReaver::LIB_DIR}/helper/attachments"
      require "#{CortexReaver::LIB_DIR}/helper/form"

      include Innate::Helper::CGI
      include Ramaze::Helper::Pages
      include Ramaze::Helper::Attachments
      include Ramaze::Helper::Form

      # Renders plain text and html to html. If parse_code isn't true, only
      # runs bluecloth on text *outside* any <code>...</code> blocks.
      def bluecloth(text, parse_code = true, increment_headers = true)
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
            j = text.index(/<code.*?>/) || text.length
            j -= 1 if j != 0
            level += 1
           
            if j != 0
              # Convert to bluecloth
              blue = BlueCloth::new(text[0..j]).to_html
              if increment_headers
                # Increment headings by two (h1, h2 are page/entry headers)
                blue.gsub!(/<(\/)?h(\d)>/) { |match| "<#{$1}h#{$2.to_i + 2}>" }
              end
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
      # page_nav: A list of sub-pages
      # attachments: A list of attachments
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
        # 1. the prefix                   image
        # 2. the link, with colon         :foo.png
        # 3. the link itself              foo.png
        # 4. the second half of the link  [name]
        # 5. the name                     name 
      #copy.gsub!(/\[\[(([^\]]+):)?([^\]]+)(\]\[([^\]]+))?\]\]/) do |match|
       copy.gsub!(/\[\[([^\]]+?)(:([^\]]+))?(\]\[([^\]]+))?\]\]/) do |match|
          prefix = $1
          path = $3
          name = $5

          # Name of the link
          name ||= path

          Ramaze::Log.debug prefix

          # Create link to this target
          case prefix
          when 'attachments'
            # A list of attachments
            attachment_list self
          when 'image'
            # Create an inline image
            target = attachment(path)
            "<img class=\"attachment\" src=\"#{target.public_path}\" alt=\"#{name.gsub('"', '&quot;')}\" title=\"#{name.gsub('"', '&quot')}\" />"
          when 'page_nav'
            # Create a page table of contents
            subpage_navigation self
          when 'url'
            # Create a URL
            target = attachment(path)
            target.public_path
          else
            # Create a full link
            target = attachment(path)
            "<a href=\"#{target.public_path}\">#{Rack::Utils.escape_html(name).gsub(/#([{@$]@?)/, '&#35;\1')}</a>"
          end
        end
       
        copy
      end

      def syntax_highlight(text)
        return text if text.nil?

        text = text.gsub(/<cr:code([^>]+lang="([a-z0-9]+)".*?)?>(.*?)<\/cr:code>/m) do |match|
          lang = $2 || 'text'
          code = $3

          # Tempfile...
          Tempfile.open('cortex-reaver') do |f|
            f.write code.strip
            f.close

            system('vim -f +"set filetype=' + lang + '" +"syn on" +"let html_use_css = 1" +"let html_use_encoding = \"UTF-8\"" +"let use_xhtml = 1" +"run! syntax/2html.vim" +"wq" +"q" ' + f.path)

            code = File.read(f.path + '.html')
            File.delete(f.path + '.html')
            f.unlink
          end

          # Slice out preamble
          code.sub!(/^.*?<pre>/m, '')
          code.sub!(/<\/pre>.*$/m, '')

          # Wrap
          code = '<code class="block">' + code.strip + '</code>' 
          code
        end
        text
      end

      def sanitize_html(html)
        return html if html.nil?

        Sanitize.clean(html, Sanitize::Config::BASIC)
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
