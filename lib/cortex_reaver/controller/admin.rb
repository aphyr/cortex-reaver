module CortexReaver
  class AdminController < Controller
    
    map '/admin'

    layout(:text) do
      not request.xhr?
    end

    helper :aspect
    
    before_all do
      require_roles :admin
    end

    def index
    end

    # Recalculate comment counts
    def update_comments
      [Journal, Page, Project, Photograph].each do |klass|
        klass.refresh_comment_counts
      end

      flash[:notice] = "Comment counts updated."
      redirect Rs()
    end

    # Recalculate tag counts and vacuum unused tags
    def update_tags
      @updated = Tag.refresh_counts
      @deleted = []
      Tag.unused.order(:title).all.each do |tag|
        @deleted << tag.destroy
      end
    end
  end
end
