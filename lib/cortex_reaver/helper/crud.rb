module Ramaze
  module Helper
    # Provides list, create, read, update, and delete functionality for Cortex
    # Reaver. Centralizes the lookup and database logic for re-use across
    # several models.
    #
    # Requires pagination, auth, workflow, and feeds
    module Crud
      require 'builder'

      Helper::LOOKUP << self

      def self.included(base)
        base.instance_eval do
          # Provides on_save, on_create, on_update callbacks for controllers, 
          # which defines how the controller CRUD sets attributes on the 
          # primary model.

          # This block is called when a new model is being created. The model
          # and request are passed to the block. The resulting model is stored
          # in the database. Example:
          #
          # JournalController.on_save do |journal, request|
          #   journal.title = request[:title]
          #   journal.body = request[:body].downcase
          # end
          
          def self.on_create(&block)
            unless block_given? and block.arity == 2
              raise ArgumentError.new("needs a block with two arguments")
            end
            @on_create = block
          end

          def self.on_update(&block)
            unless block_given? and block.arity == 2
              raise ArgumentError.new("needs a block with two arguments")
            end
            @on_update = block
          end

          def self.on_save(&block)
            unless block_given? and block.arity == 2
              raise ArgumentError.new("needs a block with two arguments")
            end
            @on_save = block
          end

          def self.on_second_save(&block)
            unless block_given? and block.arity == 2
              raise ArgumentError.new("needs a block with two arguments")
            end
            @on_second_save = block
          end

          def self.on_create_block
            @on_create
          end

          def self.on_save_block
            @on_save
          end

          def self.on_second_save_block
            @on_second_save
          end

          def self.on_update_block
            @on_update
          end
        end

        base.class_eval do
          # Check that MODEL is defined, so we know what we're working with.
          unless const_defined?('MODEL')
            raise RuntimeError.new("can't use CRUD helper unless MODEL is set.")
          end

          # Set the singular and plural instance vars for MODEL.
          unless const_defined?('SINGULAR_MODEL_VAR')
            const_set('SINGULAR_MODEL_VAR', '@' + const_get('MODEL').to_s.demodulize.underscore)
          end
          unless const_defined?('PLURAL_MODEL_VAR')
            const_set('PLURAL_MODEL_VAR', const_get('SINGULAR_MODEL_VAR').pluralize)
          end

          # Prevent conflicts with our 0-ary action methods.  Not needed if
          # we're using controller/show/name instead of controller/name
          #
          #begin
          #  const_get('MODEL').reserved_canonical_names += ['index', 'new']
          #rescue
          #end

          # This action can't be in the normal module body, or it breaks things.
          def new
            require_admin

            @title = "New #{h model_class.to_s.demodulize.titleize}"
            @form_action = :new

            if request.post?
              begin
                # Create model
                CortexReaver.db.transaction do
                  @model = model_class.new

                  # Initial callbacks
                  if block = self.class.on_save_block
                    block.call(@model, request)
                  end
                  if block = self.class.on_create_block
                    block.call(@model, request)
                  end

                  # Save for the first time
                  raise unless @model.save

                  # Second save callback, if applicable
                  if block = self.class.on_second_save_block
                    block.call(@model, request)
                    raise unless @model.save
                  end

                  flash[:notice] = "Created #{model_class.to_s.demodulize.downcase} #{h @model.to_s}."
                  redirect @model.url
                end
              rescue => e
                # An error occurred
                Ramaze::Log.error e.inspect + e.backtrace.join("\n")
                flash[:error] = "Couldn't create #{model_class.to_s.demodulize.downcase} #{h request[:title]}: #{h e}."
                set_singular_model_var @model
              end
            else
              set_singular_model_var model_class.new
            end
          end
        end
      end

      private

      # Returns the model class for this controller, e.g., 'Journal'
      def model_class
        self.class.const_get('MODEL')
      end

      # Set the singular instance var for this controller, e.g. '@journal'.
      def set_singular_model_var(value)
        instance_variable_set(self.class.const_get('SINGULAR_MODEL_VAR'), value)
      end

      # Set the plural instance var for this controller, e.g. '@journals'
      def set_plural_model_var(value)
        instance_variable_set(self.class.const_get('PLURAL_MODEL_VAR'), value)
      end

      public

      # Normal actions start here.

      def index(id = nil)
        if id
          # Redirect to show
          #
          # This way, you can (assuming your name doesn't conflict with an existing
          # action) tell people to visit /journals/my-cool-event, and it will go to
          # /journals/show/my-cool-event.
          raw_redirect Rs(:show, id), :status => 301
        else
          # Display index
          page :last
        end
      end

      def delete(id)
        require_admin

        if @model = model_class.get(id)
          if @model.destroy
            flash[:notice] = "#{model_class.to_s.demodulize.downcase} #{h @model.to_s} deleted."
            redirect Rs()
          else
            flash[:notice] = "Couldn't delete #{model_class.to_s.demodulize.downcase} #{h @model.to_s}."
            redirect @model.url
          end
        else
          flash[:error] = "No such #{model_class.to_s.demodulize.downcase} (#{h id}) exists."
          redirect Rs()
        end
      end

      def edit(id = nil)
        require_admin

        if @model = model_class.get(id)
          @title = "Edit #{model_class.to_s.demodulize.downcase} #{h @model.to_s}"
          if @model.class.respond_to? :canonical_name_attr
            @form_action = "edit/#{@model.send(@model.class.canonical_name_attr)}"
          else
            @form_action = "edit/#{@model.id}"
          end

          set_singular_model_var @model

          if request.post?
            begin
              # Update model
              CortexReaver.db.transaction do
                # Initial callbacks
                if block = self.class.on_save_block
                  block.call(@model, request)
                end
                if block = self.class.on_update_block
                  block.call(@model, request)
                end

                # Save
                raise unless @model.save

                # Second callbacks and save if applicable
                if block = self.class.on_second_save_block
                  block.call(@model, request)
                  raise unless @model.save
                end

                flash[:notice] = "Updated #{model_class.to_s.demodulize.downcase} #{h @model.to_s}."
                redirect @model.url
              end
            rescue => e
              # An error occurred
              Ramaze::Log.error e.inspect + e.backtrace.join("\n")
              flash[:error] = "Couldn't update #{model_class.to_s.demodulize.downcase} #{h @model.to_s}: #{h e}."
            end
          end
        else
          flash[:error] = "No such #{model_class.to_s.demodulize.downcase} (#{id}) exists."
          redirect Rs()
        end
      end

      def page(page)

        page = case page
        when Symbol
          page
        when 'first'
          :first
        when 'last'
          :last
        when nil
          error_404
        else
          page.to_i
        end

        @title = "#{model_class.to_s.demodulize.pluralize.titleize}"
        if self.class.private_method_defined? :feed and model_class.respond_to? :atom_url
          feed @title, model_class.atom_url
        end
        @models = model_class.window(page)
        @page = page

        if model_class.count.zero?
          # There are NO models
        elsif @models.empty?
          # Empty page
          error_404
        end

        set_plural_model_var @models

        workflow "New #{model_class.to_s.demodulize}", Rs(:new)

        render_template :list
      end

      def show(id)
        if id and @model = model_class.get(id)
          # Found that model
          # Redirect IDs to names
          raw_redirect(@model.url, :status => 301) if id =~ /^\d+$/

          @title = h @model.to_s
          set_singular_model_var @model

          # Retrieve pending comment from session, if applicable.
          if comment = session[:pending_comment] and comment.parent == @model
            @new_comment = session.delete :pending_comment
          else
            # Create a comment to be posted
            @new_comment = CortexReaver::Comment.new
            @new_comment.send("#{model_class.to_s.demodulize.underscore.downcase}=", @model)
          end

          if session[:user]
            @new_comment.user = session[:user]
          end
          
          # ID component of edit/delete links
          if @model.class.respond_to? :canonical_name_attr
            id = @model.send(@model.class.canonical_name_attr)
          else
            id = @model.id
          end

          workflow "Edit this #{model_class.to_s.demodulize}", Rs(:edit, id)
          workflow "Delete this #{model_class.to_s.demodulize}", Rs(:delete, id)
          render_template :show
        elsif id
          # Didn't find that model
          error_404
        end
      end
    end
  end
end
