module Ramaze
  module Helper
    module Pages
      # Gives a list of lists showing page heirarchy navigation. Expands to show
      # the current page if given.
      def page_navigation(current=nil)
        l = "<ol>\n"
        CortexReaver::Page.top.all.each do |page|
          l << page_navigation_helper(page, current)
        end
        l << '</ol>'
      end

      def page_navigation_helper(page, current=nil)
        l = '<li' + (page == current ? ' class="selected"' : '') + '>'
        l << "<a href=\"#{page.url}\">#{h page.title}</a>"
        if page.pages and current.within? page
          l << "\n<ol>"
          page.pages.each do |page| 
            l << page_navigation_helper(page, current)
          end
          l << "</ol>\n"
        end
        l << "</li>\n"
      end

      # Returns a page selector
      def page_select(id, params={})
        type = params[:type]
        p_class = params[:p_class]
        description = params[:description] || id.to_s.titleize
        model = params[:model]
        default_id = params[:default_id]
        skip_id = params[:skip_id]

        f = "<p #{p_class.nil? ? '' : 'class="' + attr_h(p_class) + '"'}>"
        f << "<label for=\"#{id}\">#{description}</label>"
        f << "<select name=\"#{id}\" id=\"#{id}\">"
        f << "<option value="">/</option>"
        CortexReaver::Page.top.order(:title).all.each do |page|
          f << page_select_helper(page, default_id, skip_id)
        end
        f << "</select></p>"
      end

      private

      def page_select_helper(page, default_id=nil, skip_id=nil, depth=0)
        s = '<option' +
            (page.id == default_id ? ' selected="selected"' : '') +
            (page.id == skip_id ? ' disabled="disabled"' : '') +
            " value=\"#{page.id}\">" +
            '&nbsp;&nbsp;' * depth +
            "#{h page.title}</option>\n"
        page.pages_dataset.order(:title).all.each do |page|
          s << page_select_helper(page, default_id, skip_id, depth + 1)
        end
        s
      end
    end
  end
end
