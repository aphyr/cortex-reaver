module CortexReaver
  class CommentController < Ramaze::Controller
    MODEL = Comment

    map '/comments'
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
      :canonical,
      :crud,
      :feeds

    cache :index, :ttl => 60

    on_save do |comment, request|
      comment.title = request[:title]
      comment.body = request[:body]
      comment.comment_id = request[:comment_id]
      comment.journal_id = request[:journal_id]
      comment.photograph_id = request[:photograph_id]
      comment.project_id = request[:project_id]
    end

    on_create do |comment, request|
      # User-specific properties
      if session[:user]
        # A user is logged in.
        comment.user = session[:user]
      else
        # Save the anonymous comment.
        comment.name = request[:name].blank? ? nil : request[:name]
        comment.email = request[:email].blank? ? nil : request[:email]
        comment.http = request[:http].blank? ? nil : request[:http]
      end
    end

    for_feed do |comment, x|
      x.content comment.body_cache, :type => 'html'
    end

    # We only really care about tracking recent comments.
    def page(page)
      @title = "Recent Comments"
      @comments = Comment.order(:created_on).reverse.limit(16)

      render_template :list
    end

    # This action is referenced by public comment-posting forms.
    def post
      unless request.post?
        flash[:error] = "No comment to post!"
        redirect_to R(:/)
      end
     
      # Check for robots
      unless request[:captcha].blank? and
             request[:comment].blank?
        # Robot!?
        flash[:error] = "Cortex Reaver is immune to your drivel, spambot."
        redirect R(:/)
      end 

      begin
        # Create comment
        CortexReaver.db.transaction do
          @comment = Comment.new

          @comment.title = request[:title]
          @comment.body = request[:body]
          @comment.comment_id = request[:comment_id]
          @comment.journal_id = request[:journal_id]
          @comment.photograph_id = request[:photograph_id]
          @comment.project_id = request[:project_id]

          if session[:user]
            # A user is logged in. Use their account.
            @comment.user = session[:user]
          else
            # Use anonymous info, if it won't conflict.
            if User.filter(:email => request[:email]).count > 0
              # Conflicts!
              flash[:error] = "Sorry, that email address belongs to a registered user. Would you like to <a href=\"/user/login\">log in</a>? Your comment will still be here when you get back."
              
              # Save comment and go back to the parent.
              session[:pending_comment] = @comment
              redirect comment.parent.url
            else
              # Okay, set anonymous info
              @comment.name = request[:name] unless request[:name].blank?
              @comment.email = request[:email] unless request[:email].blank?
              @comment.http = request[:http] unless request[:http].blank?
            end
          end

          # Save
          raise unless @comment.save

          # Clear action cache
          action_cache.delete '/index'

          flash[:notice] = "Your comment (<a href=\"##{@comment.url.gsub(/.*#/, '')}\">#{h @comment.title}</a>) has been posted."
          redirect @comment.parent.url
        end
      rescue => e
        # An error occurred
        Ramaze::Log.error e.inspect + e.backtrace.join("\n")
        flash[:error] = "We couldn't post your comment."

        if @comment.parent
          session[:pending_comment] = @comment
          redirect @comment.parent.url + '#post-comment'
        else
          redirect R(:/)
        end
      end
    end 
  end
end
