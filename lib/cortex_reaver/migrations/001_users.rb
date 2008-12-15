module CortexReaver
  class UserSchema < Sequel::Migration
    def down
      drop_table :users if table_exists? :users
    end

    def up
      unless table_exists? :users
        create_table :users do
          primary_key :id
          varchar :login, :index => true, :unique => true, :null => false
          varchar :name
          varchar :http
          varchar :email
          varchar :password
          varchar :salt
          boolean :admin, :default => false
          datetime :created_on, :null => false 
          datetime :updated_on, :null => false
        end
      end
    end
  end
end
