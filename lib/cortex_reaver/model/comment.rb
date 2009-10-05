module CortexReaver
    class Comment < Sequel::Model(:comments)
    plugin :timestamps
    plugin :cached_rendering
    plugin :comments
    plugin :sequenceable
    
    include CortexReaver::Model::Renderer
    
    many_to_one :creator, :class => 'CortexReaver::User', :key => 'created_by'
    many_to_one :updater, :class => 'CortexReaver::User', :key => 'updated_by'
    many_to_one :journal, :class => 'CortexReaver::Journal'
    many_to_one :project, :class => 'CortexReaver::Project'
    many_to_one :photograph, :class => 'CortexReaver::Photograph'
    many_to_one :page, :class => 'CortexReaver::Page'
    many_to_one :comment, :class => 'CortexReaver::Comment'
    one_to_many :comments, :class => 'CortexReaver::Comment'

    # Infer blank titles
    def before_save
      return false unless super

      if title.blank?
        title = 'Re: ' + parent.title.to_s
        title.gsub!(/^(Re: )+/, 'Re: ')
        self.title = title
      end

      true
    end

    # Update parent comment counts
    def before_destroy
      return false unless super

      parent = self.parent
      parent.comment_count -= 1
      parent.skip_timestamp_update = true
      parent.save

      true
    end
    
    # Increment parent comment count
    # WARNING: If we *reparent* comments as opposed to just posting, this will
    # break.
    def after_create
      super

      parent = self.parent
      parent.comment_count += 1
      parent.skip_timestamp_update = true
      parent.save

      true
    end

    render :body, :with => :render_comment
    
    def self.get(id)
      self[id]
    end

    def self.recent
      reverse_order(:created_on).limit(16)
    end

    def self.url
      '/comments'
    end

    def self.infer_blank_titles
      self.all.each do |comment|
        if comment.title.blank?
          comment.title = 'Re: ' + comment.parent.title.to_s
          comment.title.gsub!(/^(Re: )+/, 'Re: ')
          comment.skip_timestamp_update = true
          comment.save
        end
      end
    end

    def to_s
      title || 'comment ' + id.to_s
    end

    def url
      root_parent.url + '#comment_' + id.to_s
    end

    def validate
      validates_presence :body
      validates_max_length 255, :title, :allow_blank => true
      validates_max_length 255, :name, :allow_blank => true 
      validates_max_length 255, :http, :allow_blank => true
      validates_max_length 255, :email, :allow_blank => true
      validates_format(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :email, :allow_blank => true)

      # Ensure comments with an email specified do *not* conflict with another
      # user.
      if (not email.blank?) and User.filter(:email => email).count > 0
        self.errors[:email] << 'conflicts with a registered user'
      end

      # Ensures comments belong to exactly one parent.
      count = 0
      [:page_id, :project_id, :journal_id, :comment_id, :photograph_id].each do |field|
        unless self[field].blank?
          count += 1
          if count > 1
            self.errors[attribute] << 'has too many kinds of parents'
            break
          end
        end
      end

      if count == 0
        self.errors[attribute] << "doesn't have a parent"
      end
    end
  end
end
