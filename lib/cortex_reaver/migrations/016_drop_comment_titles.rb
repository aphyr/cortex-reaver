module CortexReaver
  class DropCommentTitlesSchema < Sequel::Migration
    def down
      alter_table(:comments) { add_column :varchar, :title }
    end

    def up
      if CortexReaver.db[:comments].filter(:title => nil).invert.count > 0
        puts "About to drop titles on comments. Hit enter to confirm, ctrl-c to cancel."
        gets
      end
                
      alter_table(:comments) { drop_column :title }
    end
  end
end
