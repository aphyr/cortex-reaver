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
          c = CortexReaver.config
          errors = {}
          
          # Site
          c.site.url = request['site.url']
          c.site.name = request['site.name']
          c.site.description = request['site.description']
          c.site.keywords = request['site.keywords']
          c.site.author = request['site.author']
          
          errors['site.url'] = "isn't a URL" unless c.site.url =~ /^http:\/\/.+/
          errors['site.name'] = "is blank" if c.site.name.blank?
          errors['site.author'] = "is blank" if c.site.author.blank?

          # View sections
          c.view.sections.clear
          request['view.sections'].split("\n").each do |line|
            parts = line.strip.split(' ')
            if parts.size > 1
              c.view.sections << [parts[0..-2].join(' '), parts[-1]]
            end
          end

          # Photographs
          c.photographs.sizes = Construct.new
          request['photographs.sizes'].split("\n").each do |line|
            parts = line.strip.split(' ', 2)
            if parts.size > 1
              c.photographs.sizes[parts.first] = parts.last
            end
          end

          if errors.empty?
            # Save
            CortexReaver.instance_variable_set '@config', c
            CortexReaver.config.save
            flash[:notice] = "Configuration saved."
            redirect rs
          else
            flash[:error] = "Configuration errors."
            @config = c
            @errors = errors
          end
        rescue => e
          Ramaze::Log.error e.inspect + e.backtrace.join("\n")
          flash[:error] = "Unable to update configuration: #{h e}"
          @config = c
          @errors = {}
        end
      else
        @config = CortexReaver.config
        @errors = {}
      end
    end

    # Recalculate comment counts
    def update_comments
      [Journal, Page, Photograph].each do |klass|
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

    def regenerate_caches
      [Journal, Page, Comment].each do |klass|
        klass.refresh_render_caches
      end
      redirect rs()
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
          Thread.current.priority = -2
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
