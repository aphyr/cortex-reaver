module CortexReaver
  class JournalController < Ramaze::Controller
    MODEL = Journal

    map '/journals'
    layout '/text_layout'
    deny_layout :atom
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
      :feeds

    cache :index, :ttl => 60

    on_second_save do |journal, request|
      journal.tags = request[:tags]
      add_attachments(journal, request[:attachments])
      journal.body = request[:body]
    end

    on_save do |journal, request|
      journal.title = request[:title]
      journal.name = Journal.canonicalize request[:name], journal.id
      journal.user = session[:user]
    end

    for_feed do |journal, x|
      x.content journal.body_cache, :type => 'html'
    end
  end
end
