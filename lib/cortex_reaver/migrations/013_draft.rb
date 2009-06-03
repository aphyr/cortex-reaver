module CortexReaver
  class DraftSchema < Sequel::Migration
    def down
      alter_table(:pages)       { drop_column :draft }
      alter_table(:projects)    { drop_column :draft }
      alter_table(:journals)    { drop_column :draft }
      alter_table(:photographs) { drop_column :draft }
    end

    def up
      alter_table(:pages)       { add_column :draft, :boolean, :default => false }
      alter_table(:projects)    { add_column :draft, :boolean, :default => false }
      alter_table(:journals)    { add_column :draft, :boolean, :default => false }
      alter_table(:photographs) { add_column :draft, :boolean, :default => false }
    end
  end
end
