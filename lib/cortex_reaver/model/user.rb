require 'digest/sha2'

module CortexReaver
  class User < Sequel::Model(:users)
    plugin :timestamps
    plugin :sequenceable

    one_to_many :created_comments, :key => 'created_by', :class => 'CortexReaver::Comment'
    one_to_many :created_journals, :key => 'created_by', :class => 'CortexReaver::Journal'
    one_to_many :created_pages, :key => 'created_by', :class => 'CortexReaver::Page'
    one_to_many :created_photographs, :key => 'created_by', :class => 'CortexReaver::Photograph'
    one_to_many :created_projects, :key => 'created_by', :class => 'CortexReaver::Project'
    one_to_many :updated_comments, :key => 'updated_by', :class => 'CortexReaver::Comment'
    one_to_many :updated_journals, :key => 'updated_by', :class => 'CortexReaver::Journal'
   one_to_many :updated_pages, :key => 'updated_by', :class => 'CortexReaver::Page'
    one_to_many :updated_photographs, :key => 'updated_by', :class => 'CortexReaver::Photograph'
    one_to_many :updated_projects, :key => 'updated_by', :class => 'CortexReaver::Project'


    self.window_size = 64

    # Is this the special anonymous user?
    def anonymous?
      false
    end

    # Returns an authenticated user by login and password, or nil.
    def self.authenticate(login, password)
      user = self[:login => login]
      if user and user.authenticate(password)
        user
      else
        nil
      end
    end

    # An anonymous proxy user, with no permissions.
    def self.anonymous
      # Return singleton if stored
      return @anonymous_user if @anonymous_user

      # Create anonymous user
      @anonymous_user = self.new(:name => "Anonymous")

      # These functions are embedded for speed. Much faster public browsing!
      def @anonymous_user.can_create? other
        false
      end
      def @anonymous_user.can_edit? other
        false
      end
      def @anonymous_user.can_delete? other
        false
      end
      def @anonymous_user.anonymous?
        true
      end
      
      @anonymous_user
    end

    # CRUD uses this to construct URLs. Even though we don't need the full
    # power of Canonical, CRUD is pretty useful. :)
    def self.canonical_name_attr
      :login
    end

    # Get a user
    def self.get(id)
      self[:login => id] || self[id]
    end

    # Class URL
    def self.url
      '/users'
    end

    # Returns true if the user is an administrator.
    def admin?
      self.admin
    end

    # Authenticate with password
    def authenticate(test_password)
      if self[:password] == self.class.crypt(test_password, self.salt)
        true
      else
        false
      end
    end

    # Ensure that we don't destroy the only admin.
    def before_destroy
      return false if super == false

      if admins = User.filter(:admin => true) and admins.count == 1 and admins.first.id == self.id
        self.errors.add nil, "Can't destroy the only administrator."
        return false
      end
    end

    def can_create?(other)
      if admin?
        # Administrators may create anything
        true
      elsif contributor?
        # Contributors may create anything but users
        case other
        when User
          false
        else
          true
        end
      else
        # Anyone may create a comment.
        case other
        when Comment
          true
        else
          false
        end
      end
    end

    def can_delete?(other)
      if admin?
        # Administrators may delete anything
        true
      elsif other.respond_to? :created_by and other.created_by == self.id
        # Anybody may delete their own records.
        true
      elsif editor? and not User === other
        # Editors may delete anything but users.
        true
      elsif moderator? and Comment === other
        # Moderators may delete comments.
        true
      else
        false
      end
    end

    def can_edit?(other)
      if admin?
        # Administrators may edit anything
        true
      elsif other.respond_to? :created_by and other.created_by == self.id
        # Anybody may edit their own records
        true
      elsif editor? and not User === other
        # Editors may edit anything but other users.
        true
      elsif moderator and Comment === other
        # Moderators may edit comments
        true
      else
        false
      end
    end

    def can_view?(other)
      if other.respond_to? :draft and other.draft
        # Draft
        if admin? or can_edit? other
          # User can edit this draft
          true
        else
          # Nope, not yet!
          false
        end
      else
        # Not a draft
        true
      end
    end
      
    # Returns true if user is a contributor
    def contributor?
      self.contributor
    end

    # Returns true if user is an editor
    def editor?
      self.editor
    end

    # Returns true if user is a moderator
    def moderator?
      self.moderator
    end

    # Name falls back to login if blank
    def name
      name = self[:name]
      name.blank? ? login : name
    end

    # Set user password
    def password=(password)
      self.salt ||= self.class.new_salt
      self[:password] = self.class.crypt(password, self.salt)
      @password_length = '*' * password.length
    end

    # Password confirmation
    def password_confirmation=(password)
      self.salt ||= self.class.new_salt
      @password_confirmation = self.class.crypt(password, self.salt)
    end

    def password_confirmation
      # If password_confirmation was set, use that. Otherwise, fall back
      # to the normal password, so we don't need set the confirmation every
      # time the password is updated programmatically.
      @password_confirmation || self.password
    end

    # A cache for password length, so we can validate without keeping the
    # password as plaintext.
    def password_length
      @password_length
    end

    def to_s
      if name.blank?
        login
      else
        name
      end
    end

    # A URL to view this user
    def url
      '/users/show/' + login
    end

    def validate
      validates_unique(:login, :message => "Already taken.")
      validates_max_length(255, :login, :message => "Please enter a username shorter than 255 characters.")
      validates_format(/^[A-Za-z0-9\-_]+$/, :login, :message => "Logins can only contain alphanumeric characters, dashes, and underscores.")
      validates_max_length(255, :name, :allow_blank => true, :message => "Please enter a name shorter than 255 characters.")
      validates_max_length(255, :http, :allow_blank => true, :message => "Please enter an HTTP address shorter than 255 characters.")
      validates_unique(:email, :message => "Already taken.")
      validates_max_length(255, :email, :message => "Please enter an email address shorter than 255 characters.")
      validates_format(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :email, :message => "Please enter a valid email address.")
      validates_confirmation(:password, :message => "Make sure your passwords match.")
      validates_min_length(8, :password_length, :message => "Passwords must be at least 8 characters.", :allow_nil => true)
      validates_max_length(255, :password_length, :message => "Passwords must be at most 255 characters.", :allow_nil => true)

      # Ensure an administrator is always available.
      if admins = User.filter(:admin => true) and admins.count == 1 and admins.first.id == self.id and not admin?
        errors[:admin] << "can't be unset; only one administrator left!"
      end
    end

    private
      # Valid characters for salt
      SALT_CHARS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a

      # Returns hash of password with salt.
      def self.crypt(password, salt)
        Digest::SHA512.hexdigest(password.to_s + salt.to_s)
      end

      # Returns random salt
      def self.new_salt
        salt = ''
        40.times do
          salt << SALT_CHARS[rand(SALT_CHARS.size - 1).to_i]
        end
        salt
      end

    public

    # Create default user if none exist
    if db.table_exists?(table_name) and count == 0
      u = User.new(
        :login => 'shodan',
        :name => 'Shodan',
        :email => 'shodan@localhost.localdomain',
        :admin => true
      )
      u.password = 'citadelstation'
      u.save
    end
  end
end
