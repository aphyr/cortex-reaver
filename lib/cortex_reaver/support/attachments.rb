require 'fileutils'

module Sequel
  module Plugins
    module Attachments
      # Attachments allows records to manipulate files associated with them.
      #
      # For our purposes, an attachment represents an object that is associated
      # with a single parent object. A file represents a file on disk.

      # The separator used for public (e.g. HTTP URL) paths.
      PUBLIC_PATH_SEPARATOR = '/'

      # How many bytes to read at a time when saving files.
      DEFAULT_ATTACHMENT_DIRECTORY_MODE = 0755

      module InstanceMethods
        # When we delete a record with attachments, delete the attachments
        # first.
        def before_delete
          return false if super == false
          attachments.each do |attachment|
            attachment.delete
          end

          true
        end

        # Returns a named attachment
        def attachment(name)
          Attachment.new(self, name)
        end

        # Returns the directory which contains attachments for this record.
        # Forces a save of the record if an ID does not exist.
        def attachment_path(type = :local, force_save = true)
          sep = ''
          case type
          when :local
            # We're interested in a local path on disk.
            sep = File::SEPARATOR
            path = CortexReaver.config.public_root.dup
          when :public
            # We're interested in a public (e.g. HTTP URL) path.
            sep = PUBLIC_PATH_SEPARATOR
            path = ''
          else
            raise ArgumentError.new('type must be either :local or :public')
          end

          # If we don't have an ID, save the record to obtain one.
          if force_save and id.nil?
            unless save
              # Save failed!
              return nil
            end
          end

          # Complete the path.
          path << 
            sep + 'data' + 
            sep + self.class.to_s.demodulize.underscore.pluralize + 
            sep + self.id.to_s
        end

        # Returns an array of attachments.
        def attachments
          # Unsaved new records, naturally, have no attachments.
          return [] if new?

          attachments = Array.new
          if path = local_attachment_path and File.directory? path
            begin
              attachments = Dir.open(path).reject do |name|
                # Don't include dotfiles
                name =~ /^\./
              end
              attachments.collect! do |name|
                Attachment.new self, name
              end
            rescue
              # Couldn't read the directory
            end
          end
          attachments
        end

        # Ensures the attachment directory exists.
        def create_attachment_directory
          path = local_attachment_path
          unless File.directory? path
            FileUtils.mkdir_p path, :mode => DEFAULT_ATTACHMENT_DIRECTORY_MODE
          end
        end

        # Returns the local directory which contains attachments for this
        # record.
        def local_attachment_path
          attachment_path :local  
        end

        # Returns the public directory which contains attachments for this
        # record.
        def public_attachment_path
          attachment_path :public
        end
      end

      class Attachment
        # Wraps a file associated with a parent object.

        BUFFER_SIZE = 65536
        DEFAULT_MODE = 0644
        
        attr_reader :name

        # Takes the parent record, and the short name of the file.
        def initialize(parent, name)
          if parent.nil?
            raise ArgumentError.new("Can't attach a file to nil parent!")
          end
          if name.nil? or name.empty?
            raise ArgumentError.new("Can't create a file with no name!")
          end
          if name =~ /\/\\/
            raise ArgumentError.new("Attachment name #{name.inspect} contains evil characters!")
          end

          @parent = parent
          @name = name
        end

        # Deletes the file on disk, which effectively deletes the attachment.
        def delete
          FileUtils.remove_file local_path
        end

        # Returns true if the associated file exists.
        def exists?
          File.exists? local_path
        end

        # Returns a File object for this attachment. Optionally specify a mode 
        # string, which is passed to File.new. Creates the attachment directory
        # if necessary.
        def file(how = 'r', mode = nil)
          @parent.create_attachment_directory
          if mode
            File.new local_path, how, mode
          else
            File.new local_path, how
          end
        end

        # Replaces the file for this attachment. Readable should act like an IO
        # object, but doesn't necessarily have to be a file. If readable
        # supports #path, copies or moves using FileUtils. Creates the
        # attachment directory if necessary. Resets permissions.
        #
        # If readable *is* a file mode behaves thus:
        #   :hard_link adds a new hard link to readable's path
        #   :soft_link adds a new symlink to readable's path
        #   :copy copies the file contents using FileUtils.cp
        #   :move moves the file.
        #
        # Ramaze offers us temporary File objects from form uploads. Creating a
        # hard link is extremely quick, saves disk space, but also doesn't
        # interfere with the temporary file in case someone else wants access
        # to it.
        def file=(readable, mode = :hard_link)
          # Create attachment directory if necessary.
          @parent.create_attachment_directory

          if readable.respond_to? :path
            ret = case mode
            when :hard_link
              begin
                FileUtils.rm local_path if File.exist? local_path
                FileUtils.ln readable.path, local_path
              rescue
                # Hmm, try copy. Could be a cross-device link, or the FS
                # doesn't support it.
                FileUtils.copy readable.path, local_path
              end
            when :copy
              FileUtils.rm local_path if File.exist? local_path
              FileUtils.copy readable.path, local_path
            when :move
              FileUtils.rm local_path if File.exist? local_path
              FileUtils.move readable.path, local_path
            else
              raise RuntimeError.new("mode must be :hard_link :copy, or :move--got #{mode.inspect}")
            end
            reset_permissions
            ret
          else
            # Use read()

            # Rewind the IO, in case it's been read before.
            readable.rewind

            # Write the file
            buffer = ''
            File.open(local_path, 'w', DEFAULT_MODE) do |output|
              while readable.read BUFFER_SIZE, buffer
                output.write buffer
              end
            end
          end
        end

        # Returns the local path to this file.
        def local_path
          path :local
        end

        # Returns the path to this file.
        def path(type = :local)
          case type
          when :local
            @parent.attachment_path(type) + File::SEPARATOR + @name
          when :public
            @parent.attachment_path(type) + PUBLIC_PATH_SEPARATOR + @name
          else
            raise ArgumentError.new("Type must be either :local or :public.")
          end
        end

        # Returns the public path to this file
        def public_path
          path :public
        end

        # Resets permissions to default
        def reset_permissions
          FileUtils.chmod(DEFAULT_MODE, path(:local))
        end
      end
    end
  end
end

CortexReaver::Attachment = Sequel::Plugins::Attachments::Attachment
