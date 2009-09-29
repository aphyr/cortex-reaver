module CortexReaver
  class Photograph < Sequel::Model(:photographs)
    plugin :timestamps
    plugin :canonical
    plugin :attachments
    plugin :comments
    plugin :tags
    plugin :sequenceable
    plugin :viewable

    # Target image sizes
    SIZES = {
      :thumbnail => '164x',
      :grid => '150x150',
      :small => 'x512',
      :medium => 'x768',
      :large => 'x1024',
    }

    many_to_many :tags, :class => 'CortexReaver::Tag'
    many_to_one :creator, :class => 'CortexReaver::User', :key => 'created_by'
    many_to_one :updater, :class => 'CortexReaver::User', :key => 'updated_by'
    one_to_many :comments, :class => 'CortexReaver::Comment'

    def self.atom_url
      '/photographs/atom'
    end

    def self.get(id)
      self[:name => id] || self[id]
    end

    def self.recent
      reverse_order(:created_on).limit(16)
    end

    def self.regenerate_sizes
      all.each do |p|
        p.regenerate_sizes
      end
    end

    def self.url
      '/photographs'
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
      attachment = Attachment.new(self, 'original.jpg').file = file

      # Compute thumbnails
      regenerate_sizes

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

    # Regenerates various photo sizes.
    def regenerate_sizes
      # Find existing attachments, in order of decreasing (roughly) size
      known_files = attachments.map{|a| a.name.sub(/\.jpg$/,'')} & (SIZES.keys.map(&:to_s))
      known_files = known_files.sort_by { |f| File.stat(attachment("#{f}.jpg").path).size }.reverse
      
      # Replace original.jpg with the largest available, if necessary.
      orig = attachment 'original.jpg'
      unless orig.exists? and File.stat(orig.local_path).size > 0
        orig.file = existing.first
      end

      # Delete everything but original.jpg
      attachments.reject {|a| a.name == 'original.jpg'}.each{|a| a.delete}

      # Read image through ImageMagick
      begin
        image = Magick::Image.read(orig.local_path).first
      rescue => e
        Ramaze::Log.error "Invalid image #{orig.local_path}; not processing."
        return false
      end

      # Write appropriate sizes to disk
      SIZES.each do |size, geometry|
        image.change_geometry(geometry) do |width, height|
          attachment = attachment(size.to_s + '.jpg')
          image.scale(width, height).write(attachment.local_path)
        end

      end
        
      # Yep, GC time. Gotta clear out those imagemagick stubs.
      GC.start

      # Free IM stubs
      GC.start

      true
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

    def validate
      validates_unique :name
      validates_presence :name
      validates_max_length 255, :name
      validates_presence :title
    end
  end
end
