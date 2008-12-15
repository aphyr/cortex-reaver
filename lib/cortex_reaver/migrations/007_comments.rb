module CortexReaver
  class CommentSchema < Sequel::Migration
    def down
      drop_table :comments if table_exists? :comments
    end

    def up
      unless table_exists? :comments
        create_table :comments do
          primary_key :id

          foreign_key :user_id, :table => :users
          index :user_id

          foreign_key :journal_id, :table => :journals
          index :journal_id
          foreign_key :photograph_id, :table => :photographs
          index :photograph_id
          foreign_key :project_id, :table => :projects
          index :project_id
          foreign_key :comment_id, :table => :comments
          index :comment_id
          foreign_key :page_id, :table => :pages
          index :page_id

          varchar :title
          text :name
          text :http
          text :email
          text :body, :default => ''
          text :body_cache, :default => ''
          integer :comment_count, :null => false, :default => 0

          datetime :created_on
          datetime :updated_on
        end
      end
    end
  end
end
