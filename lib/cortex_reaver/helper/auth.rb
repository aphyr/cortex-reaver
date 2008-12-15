module Ramaze
  module Helper
    # Provides authentication services
    module Auth
      # Is the current user an admin?
      def admin?
        u = session[:user] and u.admin?
      end

      # Tries to log in a user by login and password. If successful, sets
      # session[:user] to the user and returns that user. Otherwise returns
      # false.
      def do_login(login, password)
        if user = CortexReaver::User.authenticate(login, password)
          # Successful login
          session[:user] = user
        else
          false
        end
      end

      # Log out the current user, and returns the user object.
      def do_logout
        session.delete :user
      end

      def require_admin
        if session[:user] and session[:user].admin?
          true
        elsif session[:user]
          flash[:error] = "You must have administrative privileges to do this."
          redirect :/
        else
          flash[:notice] = "Please log in first."
          session[:target_uri] = request.request_uri
          redirect R(CortexReaver::UserController, :login)
        end
      end

      def error_403
        respond 'Forbidden', 403
      end
    end
  end
end
