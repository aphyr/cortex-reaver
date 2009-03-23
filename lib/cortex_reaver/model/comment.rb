module CortexReaver
    class Comment < Sequel::Model(:comments)
    include CortexReaver::Model::Timestamps
    include CortexReaver::Model::CachedRendering
    include CortexReaver::Model::Renderer
    include CortexReaver::Model::Comments
    include CortexReaver::Model::Sequenceable
    
    belongs_to :creator, :class => 'CortexReaver::User', :key => 'created_by'
    belongs_to :updater, :class => 'CortexReaver::User', :key => 'updated_by'
    belongs_to :journal, :class => 'CortexReaver::Journal'
    belongs_to :project, :class => 'CortexReaver::Project'
    belongs_to :photograph, :class => 'CortexReaver::Photograph'
    belongs_to :page, :class => 'CortexReaver::Page'
    belongs_to :comment, :class => 'CortexReaver::Comment'
    has_many :comments, :class => 'CortexReaver::Comment'

    validates do
      presence_of :body
      length_of :title, :maximum => 255, :allow_nil => true
      length_of :name, :maximum => 255, :allow_nil => true
      length_of :http, :maximum => 255, :allow_nil => true
      length_of :email, :maximum => 255, :allow_nil => true
      format_of :email,
        :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :allow_nil => true
    end

    # Ensure comments with an email specified do *not* conflict with another user.
    validates_each :email do |object, attribute, value|
      if (not value.blank?) and User.filter(:email => value).count > 0
        object.errors[attribute] << 'conflicts with a registered user'
      end
    end

    # Ensures comments belong to exactly one parent.
    validates_each :page_id do |object, attribute, value|
      count = 0
      [:page_id, :project_id, :journal_id, :comment_id, :photograph_id].each do |field|
        unless object[field].blank?
          count += 1
          if count > 1
            object.errors[attribute] << 'has too many kinds of parents'
            break
          end
        end
      end

      if count == 0
        object.errors[attribute] << "doesn't have a parent"
      end
    end

    # Infer blank titles
    before_save(:infer_title) do
      if title.blank?
        title = 'Re: ' + parent.title.to_s
        title.gsub!(/^(Re: )+/, 'Re: ')
        self.title = title
      end
    end

    # Update parent comment counts
    before_destroy(:decrement_parent_comment_count) do
      parent = self.parent
      parent.comment_count -= 1
      parent.skip_timestamp_update = true
      parent.save
    end
    
    after_save(:refresh_parent_comment_count) do
      # WARNING: If we *reparent* comments as opposed to just posting, this will break.
      parent = self.parent
      parent.refresh_comment_count
      parent.skip_timestamp_update = true
      parent.save
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

    def url
      root_parent.url + '#comment_' + id.to_s
    end

    def to_s
      title || 'comment ' + id.to_s
    end
  end
end
