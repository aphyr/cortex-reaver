module CortexReaver
  class AdminController < Ramaze::Controller
    
    map '/admin'
    layout '/text_layout'
    engine :Erubis

    helper :error,
      :auth,
      :form,
      :workflow
    
    def index
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
