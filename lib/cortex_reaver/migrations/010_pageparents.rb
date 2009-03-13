module CortexReaver
  class PageparentsSchema < Sequel::Migration
    def down
      alter_table :pages do
       # drop_index :parent_id
        drop_column :page_id
      end
    end

    def up
      alter_table :pages do
        add_index :page_id
        add_foreign_key :page_id, :pages, :key => :id
      end
    end
  end
end
