require "active_record/base"

module ActiveRecord
  module ConnectionAdapters
    module CockroachDB
      class DatabaseTasks < ActiveRecord::Tasks::PostgreSQLDatabaseTasks
        def structure_dump(filename, extra_flags=nil)
          args = [
            "sql",
            "--execute", "show create all tables",
            "--database", db_config.database,
            "--format=table",
            "--insecure",
            {:out=>filename},
          ]
          run_cmd("cockroach", args, "dumping")
          remove_sql_fluff(filename)
        end

        def structure_load(filename, extra_flags=nil)
          puts "loading from: #{filename}"
          args = [
            "sql",
            "--database", db_config.database,
            "--insecure",
            {:in=>filename},
          ]
          run_cmd("cockroach", args, "loading")
        end

        private

        def remove_sql_fluff(filename)
          tempfile = Tempfile.open("uncommented_structure.sql")
          begin
            File.foreach(filename) do |line|
              if (!line.start_with?("------") && !line[/\A\s+create_statement\s+\z/] && !line.strip.end_with?("rows)"))
                tempfile << line
                removing_comments = false
              end
            end
          ensure
            tempfile.close
          end
          FileUtils.cp(tempfile.path, filename)
        end
      end
    end
  end
end

ActiveRecord::Tasks::DatabaseTasks.register_task(/cockroachdb/, ActiveRecord::ConnectionAdapters::CockroachDB::DatabaseTasks)
