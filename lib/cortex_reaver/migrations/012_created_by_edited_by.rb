module CortexReaver
  class CreatedbyeditedbySchema < Sequel::Migration
    def down
      [:journals, :comments, :pages, :photographs, :projects].each do |table|
        alter_table table do
          rename_column :created_by, :user_id, :type => :integer
          # Can't do this yet.
#          drop_column :updated_by
        end
      end
    end
    
    def up
      [:journals, :comments, :pages, :photographs, :projects].each do |table|
        alter_table table do
          rename_column :user_id, :created_by, :type => :integer
          add_foreign_key :updated_by, :users, :key => :id
          add_index :updated_by
        end
      end
    end
  end
end
