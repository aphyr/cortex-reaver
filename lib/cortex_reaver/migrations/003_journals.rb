module CortexReaver
  class JournalSchema < Sequel::Migration
    def down
      drop_table :journals if table_exists? :journals
    end

    def up
      unless table_exists? :journals
        create_table :journals do
          primary_key :id

          foreign_key :user_id, :table => :users
          index :user_id

          varchar :name, :null => false, :unique => true, :index => true
          text :title, :null => false
          text :body, :default => ''
          text :body_cache, :default => ''
          integer :comment_count, :null => false, :default => 0
          datetime :created_on, :null => false
          datetime :updated_on, :null => false
        end
      end
    end
  end
end
