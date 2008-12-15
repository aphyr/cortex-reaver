require 'builder'

module CortexReaver
  class MainController < Ramaze::Controller
    map '/'
    layout '/text_layout'
    helper :workflow, :auth, :error, :navigation, :date, :tags, :form, :feeds
    engine :Erubis

    # the index action is called automatically when no other action is specified
    def index(id = nil)
      if id and @page = Page.get(id)
        # Render that page.
        @title = @page.title
        
        workflow "Edit this page", R(PageController, :edit, @page.name)
        workflow "Delete this page", R(PageController, :delete, @page.name)

        render_template 'pages/show'
      elsif id
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

        workflow "New Page", R(JournalController, :new)
        workflow "New Project", R(JournalController, :new)
        workflow "New Journal", R(JournalController, :new)
        workflow "New Photograph", R(JournalController, :new)

        feed 'Photographs', Rs(PhotographController, :atom)
        feed 'Journals', Rs(JournalController, :atom)
        feed 'Projects', Rs(ProjectController, :atom)
        feed 'Comments', Rs(CommentController, :atom)

        render_template 'journals/list.rhtml'
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
