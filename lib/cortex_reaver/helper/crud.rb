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
          # 
          # You can also define on_save, on_second_save, and on_update methods
          # which will be called after the blocks. The difference is that the
          # block forms are evaluated in the class, and the method forms are
          # evaluated in the context of the instance.
          
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

          # This action can't be in the normal module body, or it breaks things.
          def new
            # You need to be able to create one of these.
            for_auth do |u|
              u.can_create? model_class.new
            end

            @title = "New #{model_class.to_s.demodulize.titleize}"
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
                  if respond_to? :on_save
                    on_save(@model, request)
                  end
                  if block = self.class.on_create_block
                    block.call(@model, request)
                  end
                  if respond_to? :on_create
                    on_create(@model, request)
                  end

                  # Save for the first time
                  raise unless @model.save

                  # Second save callback, if applicable
                  if block = self.class.on_second_save_block
                    block.call(@model, request)
                  end
                  if respond_to? :on_second_save
                    on_second_save @model, request
                  end
                  if block or respond_to? :on_second_save
                    raise unless @model.save
                  end

                  flash[:notice] = "Created #{model_class.to_s.demodulize.downcase} #{h @model.to_s}."
                  redirect @model.url
                end
              rescue => e
                # An error occurred
                Ramaze::Log.error e.inspect + e.backtrace.join("\n")

                if e.is_a? Sequel::ValidationFailed
                  flash[:error] = "Couldn't update #{model_class.to_s.demodulize.downcase} #{h @model.to_s}, because there were errors in the form."
                else
                  flash[:error] = "Couldn't create #{model_class.to_s.demodulize.downcase} #{h request[:title]}: #{h e}."
                end

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
          # This way, you can (assuming your name doesn't conflict with an
          # existing action) tell people to visit /journals/my-cool-event, and
          # it will go to /journals/show/my-cool-event.
          raw_redirect rs(:show, id), :status => 301
        else
          # Display index
          page :last
        end
      end

      def delete(id)
        if @model = model_class[id]
          for_auth do |u|
            u.can_edit? @model
          end

          begin
            raise unless @model.destroy
            flash[:notice] = "#{model_class.to_s.demodulize.downcase} #{h @model.to_s} deleted."
            redirect rs()
          rescue => e
            flash[:notice] = "Couldn't delete #{model_class.to_s.demodulize.downcase} #{h @model.to_s}."
            if @model.errors.size > 0
              flash[:notice] << ' ' + @model.errors.to_s
            else
              flash[:notice] << ' ' + e.message
            end
            redirect @model.url
          end
        else
          flash[:error] = "No such #{model_class.to_s.demodulize.downcase} (#{h id}) exists."
          redirect rs()
        end
      end

      def edit(id = nil)
        if @model = model_class[id]
          for_auth do |u|
            u.can_edit? @model
          end
        
          @title = "Edit #{model_class.to_s.demodulize.downcase} #{@model.to_s}"
          @form_action = "edit/#{@model.id}"

          set_singular_model_var @model

          if request.post?
            begin
              # Update model
              CortexReaver.db.transaction do
                # Initial callbacks
                if block = self.class.on_save_block
                  block.call(@model, request)
                end
                if respond_to? :on_save
                  on_save @model, request
                end
                if block = self.class.on_update_block
                  block.call(@model, request)
                end
                if respond_to? :on_update
                  on_update @model, request
                end

                # Save
                raise unless @model.save

                # Second callbacks and save if applicable
                if block = self.class.on_second_save_block
                  block.call(@model, request)
                end
                if respond_to? :on_second_save
                  on_second_save @model, request
                end
                if block or respond_to? :on_second_save
                  raise unless @model.save
                end

                # Invalidate caches
                Ramaze::Cache.action.clear

                flash[:notice] = "Updated #{model_class.to_s.demodulize.downcase} #{h @model.to_s}."
                redirect @model.url
              end
            rescue => e
              # An error occurred
              Ramaze::Log.error e.inspect + e.backtrace.join("\n")
              
              if e.is_a? Sequel::ValidationFailed
                flash[:error] = "Couldn't update #{model_class.to_s.demodulize.downcase} #{h @model.to_s}, because there were errors in the form."
              else
                flash[:error] = "Couldn't update #{model_class.to_s.demodulize.downcase} #{h @model.to_s}: #{h e}."
              end
            end
          end
        else
          flash[:error] = "No such #{model_class.to_s.demodulize.downcase} (#{id}) exists."
          redirect rs()
        end
      end

      def page(page = nil)
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

        if page.is_a? Integer and (page < 0 or page > model_class.window_count)
          # This page isn't in the sequence!
          error_404
        end

        @title = "#{model_class.to_s.demodulize.pluralize.titleize}"
        if self.class.private_method_defined? :feed and model_class.respond_to? :atom_url
          feed @title, model_class.atom_url
        end

        @models = model_class.window(page)
        if @models.respond_to? :viewable_by
          @models = @models.viewable_by(user)
        end

        @page = page

        set_plural_model_var @models

        if user.can_create? model_class.new
          workflow "New #{model_class.to_s.demodulize}", rs(:new), :new, model_class.to_s.demodulize.downcase
        end

        render_view(:list)
      end

      def show(id = nil)
        if id and @model = model_class.get(id)
          # Found that model
          
          unless user.can_view? @model
            error_403
          end

          # Redirect IDs to names
          raw_redirect(@model.url, :status => 301) if id =~ /^\d+$/

          @title = @model.to_s
          set_singular_model_var @model

          if @model.class.associations.include? :comments
            # Retrieve pending comment from session, if applicable.
            if comment = session[:pending_comment] and comment.parent == @model
              @new_comment = session.delete :pending_comment
            else
              # Create a comment to be posted
              @new_comment = CortexReaver::Comment.new
              @new_comment.send("#{model_class.to_s.demodulize.underscore.downcase}=", @model)
            end

            if session[:user]
              @new_comment.creator = session[:user]
            end
          end
          
          if user.can_create? model_class.new
            workflow "New #{model_class.to_s.demodulize}", rs(:new), :new, model_class.to_s.demodulize.downcase
          end
          if user.can_edit? @model
            workflow "Edit this #{model_class.to_s.demodulize}", rs(:edit, @model.id), :edit, model_class.to_s.demodulize.downcase
          end
          if user.can_delete? @model
            workflow "Delete this #{model_class.to_s.demodulize}", rs(:delete, @model.id), :delete, model_class.to_s.demodulize.downcase
          end
        elsif id
          # Didn't find that model
          error_404
        end
      end
    end
  end
end
