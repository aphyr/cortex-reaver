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

    helper :error,
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


    on_save do |photograph, request|
      photograph.title = request[:title]
      photograph.name = Photograph.canonicalize request[:name], photograph.id
      photograph.user = session[:user]
    end

    on_second_save do |photograph, request|
      photograph.tags = request[:tags]
      photograph.image = request[:image][:tempfile] if request[:image]
      photograph.infer_date_from_exif! if request[:infer_date]
    end

    for_feed do |photograph, x|
      x.content render_template('atom_fragment.rhtml', :photograph => photograph)
    end
  end
end
