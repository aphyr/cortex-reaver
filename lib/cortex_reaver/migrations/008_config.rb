module CortexReaver
  class ConfigSchema < Sequel::Migration
    def down
      drop_table :config if table_exists? :config
    end

    def up
      unless table_exists? :config
        create_table :config do
          primary_key :id
          varchar :name
          varchar :author
          varchar :description
          boolean :debug, :default => false
          varchar :url
          text :keywords
          datetime :created_on, :null => false
          datetime :updated_on, :null => false
        end
      end
    end
  end
end
