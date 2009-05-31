module CortexReaver
  class Photograph < Sequel::Model(:photographs)
   
    include CortexReaver::Model::Timestamps
    include CortexReaver::Model::Canonical
    include CortexReaver::Model::Attachments
    include CortexReaver::Model::Comments
    include CortexReaver::Model::Tags
    include CortexReaver::Model::Sequenceable

    # Target image sizes
    SIZES = {
      :thumbnail => '150x',
      :grid => '150x150',
      :small => 'x512',
      :medium => 'x768',
      :large => 'x1024',
    }

    many_to_many :tags, :class => 'CortexReaver::Tag'
    belongs_to :creator, :class => 'CortexReaver::User', :key => 'created_by'
    belongs_to :updater, :class => 'CortexReaver::User', :key => 'updated_by'
    has_many :comments, :class => 'CortexReaver::Comment'

    validates do
      uniqueness_of :name
      presence_of :name
      length_of :name, :maximum => 255
      presence_of :title
    end

    def self.atom_url
      '/photographs/atom'
    end

    def self.get(id)
      self[:name => id] || self[id]
    end

    def self.recent
      reverse_order(:created_on).limit(16)
    end

    def self.url
      '/photographs'
    end
 
    # Returns a dataset of models viewable by this user.
    def self.viewable_by(user, dataset = self.dataset)
      if user.anonymous?
        # Show only non-drafts
        dataset.exclude(:draft)
      elsif user.admin? or user.editor?
        # Show everything
        dataset
      else
        # Show all non-drafts and any drafts we created
        dataset.filter((:draft => false) | (:created_by => user.id))
      end
    end
    
    def atom_url
      '/photographs/atom/' + name
    end

    # Returns the exif data for this photograph
    def exif
      EXIFR::JPEG.new(self.full_local_path).exif
    end

    # Gives the best guess for this photograph's date.
    def date
      if exif = self.exif
        fields = [:date_time_original, :date_time_digitized, :date_time]
        fields.each do |field|
          begin
            if date = exif.send(field)
              return date
            end
          rescue
          end
        end
      end

      # Fall back on creation date
      self.created_on
    end

    # Store an photograph on disk in the appropriate sizes.
    def image=(file)
      if file.blank? or file.size == 0
        return nil
      end

      # Write file to disk
      attachment = Attachment.new(self, 'original.jpg')
      attachment.file = file

      # Read image through ImageMagick
      image = Magick::Image.read(attachment.local_path).first

      # Write appropriate sizes to disk
      SIZES.each do |size, geometry|
        image.change_geometry(geometry) do |width, height|
          attachment = Attachment.new(self, size.to_s + '.jpg')
          image.scale(width, height).write(attachment.local_path)
        end
      end

      true
    end

    # Sets the date from the EXIF date tag.
    def infer_date_from_exif!
      if exif = self.exif
        self.created_on = self.date
      end
    end

    # Returns the system path to the full photograph
    def full_local_path
      path :local, 'medium'
    end

    # Returns the path to the full photograph
    def full_public_path
      path :public, 'medium'
    end

    # The path to a photograph
    def path(type = :local, size = :full)
      attachment(size.to_s + '.jpg').path(type)
    end

    # Returns the system path to the thumbnail photograph
    def thumbnail_local_path
      path :local, 'thumbnail'
    end

    # Returns the path to the thumbnail photograph
    def thumbnail_public_path
      path :public, 'thumbnail'
    end

    def to_s
      title || name
    end

    def url
      '/photographs/show/' + name
    end
  end
end
