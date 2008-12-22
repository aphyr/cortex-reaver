module CortexReaver
  class ProjectController < Ramaze::Controller
    MODEL = Project

    map '/projects'
    layout '/text_layout'
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

    on_second_save do |project, request|
      project.tags = request[:tags]
      add_attachments(project, request[:attachments])
    end

    on_save do |project, request|
      project.title = request[:title]
      project.description = request[:description]
      project.name = Journal.canonicalize request[:name], project.id
      project.body = request[:body]
      project.user = session[:user]
    end

    for_feed do |project, x|
      x.content project.body_cache, :type => 'html'
    end
  end
end
