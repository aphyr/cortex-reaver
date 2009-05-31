require 'exifr'
require 'RMagick'
module CortexReaver
  class PhotographController < Ramaze::Controller
    MODEL = Photograph

    map '/photographs'
    layout '/blank_layout'
    layout '/text_layout' => [:index, :edit, :new, :page]
    template_paths << 'view'
    template :edit, :form
    template :new, :form
    engine :Erubis

    helper :cache,
      :error,
      :auth, 
      :form, 
      :workflow, 
      :navigation, 
      :date,
      :tags, 
      :canonical,
      :crud,
      :attachments,
      :photographs,
      :feeds

    cache :index, :ttl => 60

    on_save do |photograph, request|
      photograph.title = request[:title]
      photograph.name = Photograph.canonicalize request[:name], :id => photograph.id
      photograph.draft = request[:draft]
    end

    on_second_save do |photograph, request|
      photograph.tags = request[:tags]
      photograph.image = request[:image][:tempfile] if request[:image]
      photograph.infer_date_from_exif! if request[:infer_date]

      MainController.send(:action_cache).clear
    end

    on_create do |photograph, request|
      photograph.creator = session[:user]
    end

    on_update do |photograph, request|
      photograph.updater = session[:user]
    end

    for_feed do |photograph, x|
      p photograph
      x.content(
        render_template('atom_fragment.rhtml', :photograph => photograph), 
        :type => 'html'
      )
    end
  end
end
