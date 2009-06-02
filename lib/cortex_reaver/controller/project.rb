module CortexReaver
  class ProjectController < Controller
    MODEL = Project

    map '/projects'
    
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

    on_second_save do |project, request|
      project.tags = request[:tags]
      add_attachments(project, request[:attachments])
      project.body = request[:body]

      MainController.send(:action_cache).clear
    end

    on_save do |project, request|
      project.title = request[:title]
      project.name = Project.canonicalize request[:name], :id => project.id
      project.description = request[:description]
      project.draft = request[:draft]
    end

    on_create do |project, request|
      project.creator = session[:user]
    end

    on_update do |project, request|
      project.updater = session[:user]
    end

    for_feed do |project, x|
      x.content project.body_cache, :type => 'html'
    end
  end
end
