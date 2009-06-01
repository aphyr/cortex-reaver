require 'builder'

module CortexReaver
  class MainController < Controller
    map '/'
    
    layout(:text) do |name, wish|
      !request.xhr? and name != :atom
    end

    helper :cache, 
      :date, 
      :tags, 
      :feeds,
      :pages

    cache_action(:method => :index, :ttl => 120) do
      user.id.to_i.to_s + flash.inspect
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
        @photographs = Photograph.recent.viewable_by(user)
        @journals = Journal.recent.viewable_by(user)
      
        if @photographs.count > 0
          # Show sidebar
          @sidebar ||= []
          @sidebar.unshift PhotographController.render_view('sidebar')
        end

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
        if user.can_create? Project.new
          workflow "New Project", ProjectController.r(:new)
        end

        # Feeds
        feed 'Photographs', PhotographController.r(:atom)
        feed 'Journals', JournalController.r(:atom)
        feed 'Projects', ProjectController.r(:atom)
        feed 'Comments', CommentController.r(:atom)

        JournalController.render_view('list', :journals => @journals)
      end
    end

    # TODO: We don't implement a collective ATOM feed. Yet.
    def atom
      error_404
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
