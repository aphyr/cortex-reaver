module CortexReaver
  class ProjectSchema < Sequel::Migration
    def down
      drop_table :projects if table_exists? :projects
    end

    def up
      unless table_exists? :projects
        create_table :projects do
          primary_key :id

          foreign_key :user_id, :table => :users
          index :user_id

          varchar :name, :null => false, :unique => true, :index => true
          text :title, :null => false
          text :description, :null => false, :default => ''
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
