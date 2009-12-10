module CortexReaver
  class CommentsEnabledOnPagesSchema < Sequel::Migration
    def down
      alter_table(:pages) { drop_column :comments_enabled }
    end

    def up
      alter_table(:pages) { add_column :comments_enabled, :boolean, :default => false }
    end
  end
end
