module CortexReaver
  class PageparentsSchema < Sequel::Migration
    def down
      alter_table :pages do
        # Can't undo this cleanly yet. Fracking mysql. :/
#       drop_index :page_id
#       drop_column :page_id
      end
    end

    def up
      alter_table :pages do
        add_foreign_key :page_id, :pages, :key => :id
        add_index :page_id
      end
    end
  end
end
