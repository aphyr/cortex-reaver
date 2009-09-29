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

    def self.jobs
      @jobs ||= {}
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
      redirect rs()
    end

    # Recalculate tag counts and vacuum unused tags
    def update_tags
      @updated = Tag.refresh_counts
      @deleted = []
      Tag.unused.order(:title).all.each do |tag|
        @deleted << tag.destroy
      end
    end

    def regenerate_photo_sizes_status
      if job = self.class.jobs[:regenerate_photo_sizes]
        respond "{'i':#{job[:i]},'total':#{job[:total]}}"
      else
        respond '{}'
      end
    end

    # Regenerates thumbnails on photographs
    def regenerate_photo_sizes
      unless self.class.jobs[:regenerate_photo_sizes]
        self.class.jobs[:regenerate_photo_sizes] = Thread.new do
          Thread.current[:total] = Photograph.count
          while photo = (photo ? photo.next : Photograph.first)
            Thread.current[:photo] = photo
            Thread.current[:i] = photo.position
            photo.regenerate_sizes
          end

          # Done
          self.class.jobs[:regenerate_photo_sizes] = nil
          Thread.exit
        end
      end
    end
  end
end
