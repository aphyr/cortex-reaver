require 'exifr'
require 'RMagick'
module CortexReaver
  class PhotographController < Controller
    MODEL = Photograph

    map '/photographs'

    layout(:blank) do |name, wish|
      !request.xhr? and name != :atom
    end

    layout(:text) do |name, wish|
      [:index, :edit, :new, :page].include? name
    end

    alias_view :edit, :form
    alias_view :new, :form

    helper :cache,
      :date,
      :tags, 
      :canonical,
      :crud,
      :attachments,
      :photographs,
      :feeds

    cache_action(:method => :index, :ttl => 120) do
      user.id.to_i.to_s + flash.inspect
    end

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
