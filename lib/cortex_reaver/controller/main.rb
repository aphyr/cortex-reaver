require 'libxml'

module CortexReaver
  class MainController < Controller
    map '/'
    
    layout(:text) do |name, wish|
      if request.xhr? or name == 'atom' or name == 'sitemap'
        false
      else
        true
      end
    end

    # We provide an XML sitemap.
    provide(:xml, :type => 'text/xml') do |action, value|
      Ramaze::Log.info action
      if action.method == 'sitemap'
        value
      else
        nil
      end
    end

    helper :cache, 
      :date, 
      :tags, 
      :feeds,
      :pages

    cache_action(:method => :index, :ttl => 120) do
      user.id.to_i.to_s + flash.inspect
    end
    cache_action(:method => :sitemap, :ttl => 300) do
      request.path_info
    end

    def cache
      respond Ramaze::Cache.action.stats
    end

    # the index action is called automatically when no other action is specified
    def index(*ids)
      if not ids.empty? and @page = Page.get(ids)
        # Render that page.
        @title = @page.title
       
        if user.can_edit? Page.new
          workflow "Edit this page", PageController.r(:edit, @page.id), :edit, :page
        end
        if user.can_delete? Page.new
          workflow "Delete this page", PageController.r(:delete, @page.id), :delete, :page
        end

        PageController.render_view('show')
      elsif not ids.empty?
        # Didn't have that page
        error_404
      else
        # Default welcome page
        @journals = Journal.recent.viewable_by(user)

        # Workflows
        if user.can_create? Journal.new
          workflow "New Journal", JournalController.r(:new), :new, :journal
        end
        if user.can_create? Page.new
          workflow "New Page", PageController.r(:new), :new, :page
        end
        if user.can_create? Photograph.new
          workflow "New Photograph", PhotographController.r(:new), :new, :photograph
        end

        # Feeds
        feed 'Photographs', PhotographController.r(:atom)
        feed 'Journals', JournalController.r(:atom)
        feed 'Comments', CommentController.r(:atom)

        JournalController.render_view('list', :journals => @journals)
      end
    end

    # TODO: We don't implement a collective ATOM feed. Yet.
    def atom
      error_404
    end

    # XML sitemap.
    def sitemap
      error_404 unless request.path_info =~ /\.xml$/

      doc = LibXML::XML::Document.new
      doc.root = (root = LibXML::XML::Node.new('urlset'))
      root['xmlns'] = "http://www.sitemaps.org/schemas/sitemap/0.9"
      
      # Front page
      root << (url = LibXML::XML::Node.new('url'))
        url << (loc = LibXML::XML::Node.new('loc'))
          loc << full_url('/')
        url << (lastmod = LibXML::XML::Node.new('lastmod'))
          lastmod << Time.parse(Journal.dataset.min(:updated_on).to_s).xmlschema
        url << (changefreq = LibXML::XML::Node.new('changefreq'))
          changefreq << 'hourly'
        url << (priority = LibXML::XML::Node.new('priority'))
          priority << '1.0'

      # Indexes
      [JournalController, PhotographController].each do |c|
        root << (url = LibXML::XML::Node.new('url'))
        url << (loc = LibXML::XML::Node.new('loc'))
        url << (lastmod = LibXML::XML::Node.new('lastmod'))
        url << (changefreq = LibXML::XML::Node.new('changefreq'))
        url << (priority = LibXML::XML::Node.new('priority'))
        
        loc << full_url(c.r)
        lastmod << Time.parse(c::MODEL.dataset.min(:updated_on).to_s).xmlschema
        changefreq << 'hourly'
        priority << '0.9'
      end

      # Comments
      root << (url = LibXML::XML::Node.new('url'))
      url << (loc = LibXML::XML::Node.new('loc'))
      url << (lastmod = LibXML::XML::Node.new('lastmod'))
      url << (changefreq = LibXML::XML::Node.new('changefreq'))
      url << (priority = LibXML::XML::Node.new('priority'))
      
      loc << full_url('/comments')
      lastmod << Time.parse(Comment.dataset.min(:updated_on).to_s).xmlschema
      changefreq << 'always'
      priority << '0.5'

      # Individual pages
      Page.all.each do |page|
        root << (url = LibXML::XML::Node.new('url'))
        url << (loc = LibXML::XML::Node.new('loc'))
        url << (lastmod = LibXML::XML::Node.new('lastmod'))
        url << (changefreq = LibXML::XML::Node.new('changefreq'))
        url << (priority = LibXML::XML::Node.new('priority'))

        loc << full_url(page.url)
        lastmod << page.updated_on.xmlschema
        changefreq << 'weekly'
        priority << '0.9'
      end
      Journal.all.each do |journal|
        root << (url = LibXML::XML::Node.new('url'))
        url << (loc = LibXML::XML::Node.new('loc'))
        url << (lastmod = LibXML::XML::Node.new('lastmod'))
        url << (changefreq = LibXML::XML::Node.new('changefreq'))
        url << (priority = LibXML::XML::Node.new('priority'))
      
        loc << full_url(journal.url)
        lastmod << journal.updated_on.xmlschema
        changefreq << 'weekly'
        priority << '0.8'
      end
      Photograph.all.each do |photograph|
        root << (url = LibXML::XML::Node.new('url'))
        url << (loc = LibXML::XML::Node.new('loc'))
        url << (lastmod = LibXML::XML::Node.new('lastmod'))
        url << (changefreq = LibXML::XML::Node.new('changefreq'))
        url << (priority = LibXML::XML::Node.new('priority'))
          
        loc << full_url(photograph.url)
        lastmod << photograph.updated_on.xmlschema
        changefreq << 'weekly'
        priority << '0.8'
      end

      doc
    end

    private

    # the string returned at the end of the function is used as the html body
    # if there is no template for the action. if there is a template, the string
    # is silently ignored
    def notemplate
      "there is no 'notemplate.xhtml' associated with this action"
    end
  end
end
