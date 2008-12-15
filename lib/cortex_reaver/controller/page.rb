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
      :attachments

    on_second_save do |page, request|
      page.tags = request[:tags]
      add_attachments(page, request[:attachments])
    end

    on_save do |page, request|
      page.title = request[:title]
      page.name = Page.canonicalize request[:name], page.id
      page.body = request[:body]
      page.user = session[:user]
    end
  end
end
