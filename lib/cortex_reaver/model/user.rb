require 'digest/sha2'

module CortexReaver
  class User < Sequel::Model(:users)
    include CortexReaver::Model::Timestamps
    include CortexReaver::Model::Sequenceable

    has_many :comments, :class => 'CortexReaver::Comment'
    has_many :journals, :class => 'CortexReaver::Journal'
    has_many :pages, :class => 'CortexReaver::Page'
    has_many :photographs, :class => 'CortexReaver::Photograph'
    has_many :projects, :class => 'CortexReaver::Project'

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
