module Sequel
  module Plugins
    module Viewable
      module DatasetMethods
        def viewable_by(user)
          if user.anonymous?
            self.exclude(:draft => true)
          elsif user.admin? or user.editor?
            self
          else
            self.exclude(:draft => true).or(:created_by => user.id)
          end
        end
      end
    end
  end
end
