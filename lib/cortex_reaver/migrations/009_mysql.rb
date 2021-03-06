module CortexReaver
  # Changes MySQL table engines to InnoDB
  class MySQLSchema < Sequel::Migration
    def down
      # Noop
    end
   
    def up
      db = CortexReaver.db
      begin
        if db.is_a? Sequel::MySQL::Database
          # Use InnoDB storage for everything
          db.tables.each do |table|
            db << "ALTER TABLE `#{table.to_s}` ENGINE = InnoDB;"
          end
        end
      rescue NameError
        # Not mysql!
      end
    end
  end
end
