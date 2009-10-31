module CortexReaver
  class PageController < Controller
    MODEL = Page

    map '/pages'
    
    layout(:text) do |name, wish|
      not request.xhr? and name != :atom
    end

    alias_view :edit, :form
    alias_view :new, :form

    helper :cache,
      :date,
      :tags,
      :canonical,
      :crud,
      :attachments,
      :pages

    cache_action(:method => :show, :ttl => 120) do
      user.id.to_i.to_s + flash.inspect
    end

    on_second_save do |page, request|
      Ramaze::Log.info request[:tags]
      page.tags = request[:tags]
      add_attachments(page, request[:attachments])
    end

    on_save do |page, request|
      page.title = request[:title]
      page.page_id = request[:page_id]
      page.name = Page.canonicalize request[:name], :id => page.id, :page_id => page.page_id
      page.draft = request[:draft]
      page.body = request[:body]
    end

    on_create do |page, request|
      page.creator = session[:user]
    end

    on_update do |page, request|
      page.updater = session[:user]
    end
    
    def index
      @models = @pages = Page.select(:id, :name, :title)
      workflow 'New Page', rs(:new), :new, :page
      render_view :list
    end
  end
end
