module CortexReaver
  class PhotographSchema < Sequel::Migration
    def down
      drop_table :photographs if table_exists? :photographs
    end

    def up
      unless table_exists? :photographs
        create_table :photographs do
          primary_key :id

          foreign_key :user_id, :table => :users
          index :user_id

          varchar :name, :null => false, :unique => true, :index => true
          text :title, :null => false
          integer :comment_count, :null => false, :default => 0
          datetime :created_on, :null => false
          datetime :updated_on, :null => false
        end
      end
    end
  end
end
