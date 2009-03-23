require 'digest/sha2'

module CortexReaver
  class User < Sequel::Model(:users)
    include CortexReaver::Model::Timestamps
    include CortexReaver::Model::Sequenceable

    has_many :created_comments, :key => 'created_by', :class => 'CortexReaver::Comment'
    has_many :created_journals, :key => 'created_by', :class => 'CortexReaver::Journal'
    has_many :created_pages, :key => 'created_by', :class => 'CortexReaver::Page'
    has_many :created_photographs, :key => 'created_by', :class => 'CortexReaver::Photograph'
    has_many :created_projects, :key => 'created_by', :class => 'CortexReaver::Project'
    has_many :updated_comments, :key => 'updated_by', :class => 'CortexReaver::Comment'
    has_many :updated_journals, :key => 'updated_by', :class => 'CortexReaver::Journal'
   has_many :updated_pages, :key => 'updated_by', :class => 'CortexReaver::Page'
    has_many :updated_photographs, :key => 'updated_by', :class => 'CortexReaver::Photograph'
    has_many :updated_projects, :key => 'updated_by', :class => 'CortexReaver::Project'

    validates do
      uniqueness_of :login
      length_of     :login, :with => 5..255, :allow_blank => true
      format_of     :login, :with => /^[A-Za-z0-9\-_]+$/
      length_of     :name, :maximum => 255
      length_of     :http, :allow_blank => true, :maximum => 255
      uniqueness_of :email
      length_of     :email, :allow_blank => true, :maximum => 255
      format_of     :email, 
        :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :allow_blank => true
      confirmation_of :password, :allow_nil => true#, :allow_false => true
      each(:password_length, :tag => :password_length) do |object, attribute, value|
        unless value.nil? or (8..255) === value
          object.errors['password'] << 'must be between 8 and 255 characters.'
        end
      end
    end

    # Ensure an administrator is always available.
    validates_each :admin do |object, attribute, value|
      if admins = User.filter(:admin => true) and admins.size == 1 and admins.first.id == self.id and not value
        object.errors[attribute] << "can't be unset; only one administrator left!"
      end
    end

    self.window_size = 64

    # Returns an authenticated user by login and password, or nil.
    def self.authenticate(login, password)
      user = self[:login => login]
      if user and user.authenticate(password)
        user
      else
        nil
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
      elsif other.created_by == self.id
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
      elsif other.created_by == self.id
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

    # CRUD uses this to construct URLs. Even though we don't need the full
    # power of Canonical, CRUD is pretty useful. :)
    def self.canonical_name_attr
      :login
    end

    # Get a user
    def self.get(id)
      self[:login => id] || self[id]
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

    # Returns true if user is a contributor
    def contributor?
      self.contributor
    end

    # Set user password
    def password=(password)
      self.salt ||= self.class.new_salt
      self[:password] = self.class.crypt(password, self.salt)
      @password_length = password.length
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
    if table_exists? and count == 0
      u = User.new(
        :login => 'shodan',
        :name => 'Shodan',
        :admin => true
      )
      u.password = 'shodan'
      u.save!
    end
  end
end
