module CortexReaver
  class PageSchema < Sequel::Migration
    def down
      drop_table :pages if table_exists? :pages
    end

    def up
      unless table_exists? :pages
        create_table :pages do
          primary_key :id

          foreign_key :user_id, :table => :users
          index :user_id

          varchar :name, :null => false, :unique => true, :index => true
          varchar :title, :null => false

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
