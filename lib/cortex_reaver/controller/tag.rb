module CortexReaver
  class TagController < Ramaze::Controller
    MODEL = Tag

    map '/tags'
    layout '/text_layout'
    template :edit, :form
    template :new, :form
    engine :Erubis

    helper :error,
      :auth,
      :form,
      :workflow,
      :navigation,
      :canonical,
      :crud

    on_save do |tag, request|
      tag.title = request[:title]
      tag.name = Tag.canonicalize request[:name], tag.id
    end

    def index(*ids)
      if ids.size > 0
        raw_redirect Rs([:show] + ids), :status => 301
      else
        # Index
        @title = "All Tags"
        @tags = Tag.order(:count).reverse
        render_template :list
      end
    end

    def show(*ids)
      # Find tags
      tags = []
      bad_ids = []
      ids.each do |id|
        if tag = Tag.get(id)
          tags << tag
        else
         bad_ids << id
        end
      end

      # Error message
      unless bad_ids.empty?
        flash[:error] = "No tags called #{h bad_ids.join(', ')}."
      end

      if tags.empty?
        # Index
        redirect :index
      else
        # Specific tags
        @tags = tags
        @title = "Tags: #{h tags.join(', ')}"
      end
    end

    # Tags are only created through tagging.
    def new
      error_404
    end
  end
end
