module CortexReaver
  class JournalController < Controller
    MODEL = Journal

    map '/journals'

    layout(:text) do |name, wish|
      !request.xhr? and name != 'atom'
    end

    alias_view :edit, :form
    alias_view :new, :form

    helper :cache,
      :date,
      :tags, 
      :canonical,
      :crud,
      :attachments,
      :feeds

    cache_action(:method => :index, :ttl => 120) do
      user.id.to_i.to_s + flash.inspect
    end

    on_second_save do |journal, request|
      journal.tags = request[:tags]
      add_attachments(journal, request[:attachments])
      journal.body = request[:body]
    
      MainController.send(:action_cache).clear
    end

    on_save do |journal, request|
      journal.title = request[:title]
      journal.name = Journal.canonicalize(request[:name], :id => journal.id)
      journal.draft = request[:draft]
    end

    on_create do |journal, request|
      journal.creator = session[:user]
    end

    on_update do |journal, request|
      journal.updater = session[:user]
    end

    for_feed do |journal, x|
      x.content journal.body_cache, :type => 'html'
    end
  end
end
