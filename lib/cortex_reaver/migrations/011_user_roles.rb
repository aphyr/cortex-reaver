module CortexReaver
  class UserrolesSchema < Sequel::Migration
    def down
      alter_table :users do
        drop_column :contributor
        drop_column :editor
        drop_column :moderator
      end
    end
    
    def up
      alter_table :users do
        add_column :contributor, :boolean, :default => false
        add_column :editor, :boolean, :default => false
        add_column :moderator, :boolean, :default => false
      end
    end
  end
end
