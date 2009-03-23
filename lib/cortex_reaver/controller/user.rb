module CortexReaver
  class UserController < Ramaze::Controller
    MODEL = User

    map '/users'
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
      :aspect

    on_save do |user, request|
      user.login = request[:login]
      user.name = request[:name]
      user.http = request[:http]
      user.email = request[:email]
      user.admin = request[:admin] || false

      unless request[:password].blank? and request[:password_confirmation].blank?
        # Set password
        user.password = request[:password]
        user.password_confirmation = request[:password_confirmation]
      end
    end

    # Listing users outright is a little dodgy.
    before :index do
      require_role :admin
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
            redirect R(:/)
          end
        else
          # Nope, no login.
          flash[:error] = "Wrong username or password."
          redirect Rs(:login)
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
