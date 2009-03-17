require 'builder'

module CortexReaver
  class MainController < Ramaze::Controller
    map '/'
    layout '/text_layout'
    helper :cache, 
      :workflow, 
      :auth, 
      :error, 
      :navigation, 
      :date, 
      :tags, 
      :form,
      :feeds,
      :pages

    engine :Erubis

    cache :index, :ttl => 60

    # the index action is called automatically when no other action is specified
    def index(*ids)
      if not ids.empty? and @page = Page.get(ids)
        # Render that page.
        @title = @page.title
        
        workflow "Edit this page", R(PageController, :edit, @page.id)
        workflow "Delete this page", R(PageController, :delete, @page.id)

        render_template 'pages/show'
      elsif not ids.empty?
        # Didn't have that page
        error_404
      else
        # Default welcome page
        @photographs = Photograph.recent
        @journals = Journal.recent
       
        if @photographs.size > 0
          @sidebar ||= []
          @sidebar.unshift render_template('photographs/sidebar.rhtml')
        end

        workflow "New Journal", R(JournalController, :new)
        workflow "New Page", R(PageController, :new)
        workflow "New Photograph", R(PhotographController, :new)
        workflow "New Project", R(ProjectController, :new)

        feed 'Photographs', Rs(PhotographController, :atom)
        feed 'Journals', Rs(JournalController, :atom)
        feed 'Projects', Rs(ProjectController, :atom)
        feed 'Comments', Rs(CommentController, :atom)

        render_template 'journals/list.rhtml'
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
