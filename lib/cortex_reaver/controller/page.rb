module CortexReaver
  class PageController < Ramaze::Controller
    MODEL = Page

    map '/pages'
    layout '/text_layout'
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
      :pages

    on_second_save do |page, request|
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
  end
end
