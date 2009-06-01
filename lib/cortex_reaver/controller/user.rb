module CortexReaver
  class UserController < Controller
    MODEL = User

    map '/users'
    
    layout(:text) do |name, wish|
      !request.xhr?
    end
    
    alias_view :edit, :form
    alias_view :new, :form

    helper :date,
      :tags,
      :canonical,
      :crud,
      :aspect

    on_save do |user, request|
      user.login = request[:login]
      user.name = request[:name]
      user.http = request[:http]
      user.email = request[:email]
      user.admin = request[:admin] || false
      user.editor = request[:editor] || false
      user.contributor = request[:contributor] || false
      user.moderator = request[:moderator] || false

      unless request[:password].blank? and request[:password_confirmation].blank?
        # Set password
        user.password = request[:password]
        user.password_confirmation = request[:password_confirmation]
      end
    end

    # Listing users outright is a little dodgy.
    before :index do
      for_auth do |u|
        u.admin?
      end
    end

    def login
      @title = "Login"

      if request.post?
        if user = do_login(request[:login], request[:password])
          # Successful login
          flash[:notice] = "Welcome, #{user.name}."

          if uri = session.delete(:target_uri) || request[:target_uri]
            # Send the user to their original destination.
            redirect uri
          else
            # Try the main page.
            redirect MainController.r
          end
        else
          # Nope, no login.
          flash[:error] = "Wrong username or password."
          redirect rs(:login)
        end
      end
    end

    def logout
      if user = do_logout
        flash[:notice] = "Goodbye, #{user.name}"
      end
      redirect '/'
    end  
  end
end
