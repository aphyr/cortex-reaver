module Sequel
  module Plugins
    # Support methods for comments on models
    module Comments
      module ClassMethods
        # Refresh all comment counts
        def refresh_comment_counts
          all.each do |model|
            model.refresh_comment_count
          end
        end
      end

      module InstanceMethods
        # When we delete a model that has comments, remove the comments too.
        def before_destroy
          return false if super == false

          comments = self.comments
          remove_all_comments
          comments.each do |comment|
            comment.destroy
          end

          true
        end

        # Recalculates the number of comments on this record (and all comments
        # below it, recursively) and saves those values. Returns the comment
        # count on this record.
        def refresh_comment_count
          count = 0
          comments.each do |comment|
            # Recalculate for sub-comments and sum.
            count += comment.refresh_comment_count + 1
          end
          self[:comment_count] = count
          self.skip_timestamp_update = true

          # Save and return
          self.save
          self[:comment_count]
        end

        # Returns the parent of a given comment. Caches, pass true to refresh.
        def parent(refresh = false)
          if refresh or @parent_cache.nil?
            [:comment, :journal, :photograph, :page].each do |p|
              if self.respond_to?(p) and parent = self.send(p)
                # We found an applicable parent.
                @parent_cache = parent
                return parent
              end
            end
            # We didn't find any parent
            nil
          else
            @parent_cache
          end
        end

        # Returns the top-level parent of a given comment.
        def root_parent
          if parent
            parent.root_parent
          else
            self
          end
        end
      end
    end
  end
end
