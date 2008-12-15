module CortexReaver
  class TagSchema < Sequel::Migration
    def down
      [:journals_tags, :photographs_tags, :projects_tags, :pages_tags, :tags].each do |table|
        drop_table table if table_exists? table
      end
    end

    def up
      unless table_exists? :tags
        create_table :tags do
          primary_key :id
          varchar :name, :null => false, :index => true, :unique => true
          integer :count, :null => false, :default => 0
          varchar :title, :null => false
        end
      end

      unless table_exists? :journals_tags
        create_table :journals_tags do
          primary_key :id

          foreign_key :journal_id, :table => :journals
          foreign_key :tag_id, :table => :tags
          
          unique [:journal_id, :tag_id]
        end
      end

      unless table_exists? :photographs_tags
        create_table :photographs_tags do
          primary_key :id

          foreign_key :photograph_id, :table => :photographs
          foreign_key :tag_id, :table => :tags
          
          unique [:photograph_id, :tag_id]
        end
      end

      unless table_exists? :projects_tags
        create_table :projects_tags do
          primary_key :id

          foreign_key :project_id, :table => :projects
          foreign_key :tag_id, :table => :tags
          
          unique [:project_id, :tag_id]
        end
      end

      unless table_exists? :pages_tags
        create_table :pages_tags do
          primary_key :id

          foreign_key :page_id, :table => :pages
          foreign_key :tag_id, :table => :tags
          
          unique [:page_id, :tag_id]
        end
      end
    end
  end
end
