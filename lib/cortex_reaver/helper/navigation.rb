module Ramaze
  module Helper
    # Provides navigation rendering shortcuts
    module Navigation

      # An HTML author/creation line for a model
      def author_info(model)
        s = '<span class="author-info">'
        if model.respond_to? :creator and creator = model.creator
          c = creator
        end
        if model.respond_to? :updater and updater = model.updater
          u = updater
        end

        s << '<span class="creator">'
        s << user_link(model, :creator)
        s << '</span>'
        s << ' on <span class="date">'
        s << model.created_on.strftime('%e %B %Y')
        s << '</span>'

        ct = model.created_on
        ut = model.updated_on
        unless ut.year == ct.year and ut.month == ct.month and ut.day == ct.day
          # Show the update time as well
          if u.nil? or c == u
            s << ' (updated'
          else
            s << ' (updated by '
            s << '<span class="updater">'
            s << user_link(model, :updater)
            s << '</span>'
          end
          s << ' on <span class="date">'
          s << ut.strftime('%e %B %Y')
          s << '</span>)'
        end
        s << '</span>'
      end

      # Returns a full URL from a relative one.
      def full_url(relative)
        "#{CortexReaver.config.site.url.chomp('/')}#{relative}"
      end

      # Returns a list with next/up/previous links for the record.
      def model_nav(model)
        if not model.respond_to? :next
          # Not applicable
          return
        elsif CortexReaver::User === model or CortexReaver::Page === model
          return
        end

        n = '<ul class="' + model.class.to_s.underscore + ' navigation actions">'
        if model.previous
          n << '  <li><a class="previous" href="' + model.previous.url + '">&laquo; Previous ' + model.class.to_s.demodulize + '</a></li>'
        end
        n << '  <li><a class="up" href="' + model.absolute_window_url + '">Back to ' + model.class.to_s.demodulize.pluralize + '</a></li>'
        if user.can_edit? model
          n << '  <li><a class="edit" href="' + r(:edit, model.id).to_s + '">Edit</a></li>'
        end
        if model.next
          n << model.id.to_s
          n << model.next.id.to_s
          n << '  <li><a class="next" href="' + model.next.url + '">Next ' + model.class.to_s.demodulize + ' &raquo;</a></li>'
        end
        n << '</ul>'
      end

      # Generate pagination links from a Sequenceable class and index.
      # The index can be :first or :last for the corresponding pages, an instance
      # of the class (in which case the page which would contain that instance
      # is highlighted, or a page number. Limit determines how many numeric links
      # to include--use :all to include all pages.
      def page_nav(klass, index = nil, limit = 14)
        # Translate :first, :last into corresponding windows.
        case index
        when :first
          page = 0
        when :last
          page = klass.window_count - 1
        when klass
          # Index is actually an instance of the target class
          page = index.window_absolute_index
        else
          # Index is a page number
          page = index.to_i
        end

        pages = Array.new
        links = '<ol class="pagination actions">'
        window_count = klass.window_count

        # Determine which pages to create links to
        if limit.kind_of? Integer and window_count > limit
          # There are more pages than we can display.

          # Default first and last pages are the size of the collection
          first_page = 1
          last_page = window_count - 2

          # The desired number of previous or next pages
          previous_pages = (Float(limit - 3) / 2).floor
          next_pages = (Float(limit - 3) / 2).floor

          if (offset = first_page - (page - previous_pages)) > 0
            # Window extends before the start of the pages
            last_page = first_page + (limit - 2)
          elsif (offset = (page + next_pages) - last_page) > 0
            # Window extends beyond the end of the pages
            first_page = last_page - (limit - 2)
          else
            # Window is somewhere in the middle
            first_page = page - previous_pages
            last_page = page + next_pages
          end

          # Generate list of pages
          pages = [0] + (first_page..last_page).to_a + [window_count - 1]
        else
          # The window encompasses the entire set of pages
          pages = (0 .. window_count - 1).to_a
        end

        if page > 0
          # Add "previous page" link.
          links << "<li><a class=\"previous\" href=\"#{klass.url}/page/#{page - 1}\">&laquo; Previous</a></li>"
        end

        # Convert pages to links
        unless pages.empty?
          pages.inject(pages.first - 1) do |previous, i|
            if (i - previous) > 1
              # These pages are not side-by-side.
              links << '<li class="elided"><span>&hellip;</span></li>'
            end

            if i == page
              # This is a link to the current page.
              links << "<li class=\"current\"><span>#{i + 1}</span></li>"
            else
              # This is a link to a different page.
              links << "<li><a href=\"#{klass.url}/page/#{i}\">#{i + 1}</a></li>"
            end

            # Remember this as the previous page.
            i
          end
        end

        if page < klass.window_count - 1
          # Add "next page" link.
          links << "<li><a class=\"next\" href=\"#{klass.url}/page/#{page + 1}\">Next &raquo;</a></li>"
        end

        links << '</ol>'
      end

      # Produces a section navigation list from an array of titles to urls.
      def section_nav(sections)
        s = "<ul class=\"actions\">\n"
        sections.each do |section|
          title = section.first
          url = section.last.to_s
          klass = url.gsub(/\//, '').gsub(/_/, '-')
          s << '<li class="' + klass
          s << ' current' if request.request_uri[url]
          s << '"><a href="' + attr_h(url) + '">'
          s << title
          s << "</a></li>\n"
        end
        s << "\n</ul>"
      end

      # Returns a link to a user.
      def user_link(x, who=:creator)
        case x
        when CortexReaver::User
          name = x.name || x.login
          "<a href=\"#{attr_h x.url}\">#{h name}</a>"
        when CortexReaver::Comment
          if x.send(who)
            # Use attached creator/whoever
            user_link x.send(who)
          else
            # Use anonymous info
            name = x.name || x.email || 'Anonymous'
            if x.email
              s = "<a href=\"mailto:#{attr_h x.email}\">#{h name}</a>"
              if x.http
                s << " (<a href=\"#{attr_h x.http}\" rel=\"nofollow\">#{h x.http}</a>)"
              end
              s
            elsif x.http
              "<a href=\"#{attr_h x.http}\" rel=\"nofollow\">#{h name}</a>"
            else
              h name
            end
          end
        else
          if x.respond_to? who
            user_link x.send(who)
          else
            raise ArgumentError.new("don't know how to make a user link to #{x.inspect}")
          end
        end
      end
    end
  end
end
