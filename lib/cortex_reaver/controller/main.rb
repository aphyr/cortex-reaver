require 'builder'

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
          workflow "Edit this page", PageController.r(:edit, @page.id)
        end
        if user.can_delete? Page.new
          workflow "Delete this page", PageController.r(:delete, @page.id)
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
          workflow "New Journal", JournalController.r(:new)
        end
        if user.can_create? Page.new
          workflow "New Page", PageController.r(:new)
        end
        if user.can_create? Photograph.new
          workflow "New Photograph", PhotographController.r(:new)
        end
#        if user.can_create? Project.new
#          workflow "New Project", ProjectController.r(:new)
#        end

        # Feeds
        feed 'Photographs', PhotographController.r(:atom)
        feed 'Journals', JournalController.r(:atom)
#        feed 'Projects', ProjectController.r(:atom)
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

      x = Builder::XmlMarkup.new(:indent => 2)
      x.instruct!

      x.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do
        # Front page
        x.url do
          x.loc full_url('/')
          x.lastmod Time.parse(Journal.dataset.min(:updated_on).to_s).xmlschema
          x.changefreq 'hourly'
          x.priority 1.0
        end

        # Indexes
        [JournalController, PhotographController, ProjectController].each do |c|
          x.url do
            x.loc full_url(c.r)
            x.lastmod Time.parse(c::MODEL.dataset.min(:updated_on).to_s).xmlschema
            x.changefreq 'hourly'
            x.priority 0.9
          end
        end

        # Comments
        x.url do
          x.loc full_url('/comments')
          x.lastmod Time.parse(Comment.dataset.min(:updated_on).to_s).xmlschema
          x.changefreq 'always'
          x.priority 0.5
        end

        # Individual pages
        Page.all.each do |page|
          x.url do
            x.loc full_url(page.url)
            x.lastmod page.updated_on.xmlschema
            x.changefreq 'weekly'
            x.priority 0.9
          end
        end
        Journal.all.each do |journal|
          x.url do
            x.loc full_url(journal.url)
            x.lastmod journal.updated_on.xmlschema
            x.changefreq 'weekly'
            x.priority 0.8
          end
        end
        Photograph.all.each do |photograph|
          x.url do
            x.loc full_url(photograph.url)
            x.lastmod photograph.updated_on.xmlschema
            x.changefreq 'weekly'
            x.priority 0.8
          end
        end
        Project.all.each do |project|
          x.url do
            x.loc full_url(project.url)
            x.lastmod project.updated_on.xmlschema
            x.changefreq 'weekly'
            x.priority 0.8
          end
        end
      end
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
