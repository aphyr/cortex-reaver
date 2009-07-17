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

    def configuration
      if request.post?
        begin
          # Update config
          # View sections
          CortexReaver.config.view.sections = []
          request['view.sections'].split("\n").each do |line|
            parts = line.strip.split(' ')
            if parts.size > 1
              CortexReaver.config.view.sections << [parts[0..-2].join(' '), parts[-1]]
            end
          end

          # Save
          CortexReaver.config.save
          flash[:notice] = "Configuration saved."
        rescue => e
          Ramaze::Log.error e.inspect + e.backtrace.join("\n")
          flash[:error] = "Unable to update configuration: #{h e}"
        end
      end
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
