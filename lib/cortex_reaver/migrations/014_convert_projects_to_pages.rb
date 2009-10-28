module CortexReaver
  class ProjectsToPagesSchema < Sequel::Migration

    def down
      # Nope. Not even going to try.
    end

    def up
      pages = self[:pages]
      projects = self[:projects]

      # Create projects page
      unless root = pages.filter(:name => 'projects').first
        pages.insert(
          :name => 'projects',
          :title => 'Projects',
          :created_on => Time.now,
          :updated_on => Time.now
        )
      end
      root = pages.filter(:name => 'projects').first

      # Migrate each project
      projects.all.each do |project|
        project_id = project[:id]

        # Create page
        project.delete :description
        project.delete :id
        project[:page_id] = root[:id]
        pages << project

        # Get page id
        page_id = pages.filter(:page_id => root[:id], :name => project[:name]).first[:id]
        
        # Reparent comments
        self[:comments].filter(:project_id => project_id).update(
          :project_id => nil,
          :page_id => page_id
        )
       
        # Copy tags
        self[:projects_tags].filter(:project_id => project_id).each do |t|
          self[:pages_tags] << {:page_id => page_id, :tag_id => t[:tag_id]}
        end

        # Move attachments
        # This is a little tricky; I'd like to deprecate the entire model at
        # some point. We assume it lives in config.public_dir/data/projects/id
        project_dir = File.join(
          CortexReaver.config.public_root, 'data', 'projects', project_id.to_s
        )
        page_dir = File.join(
          CortexReaver.config.public_root, 'data', 'pages', page_id.to_s
        )
        if File.directory? project_dir
          if File.directory? page_dir
            puts "WARNING: #{page_dir} already exists. Not moving contents of #{project_dir} into it. You should take a look."
          else
            FileUtils.move project_dir, page_dir
          end
        end
        
        projects.filter(:id => project_id).delete
      end

      # Drop associated columns
      # Can't do this yet--foreign key constraints...
#      alter_table :comments do
#        drop_column :project_id
#      end

      # Drop projects table
      unless table_exists? :projects
        drop_table :projects
      end
    end
  end
end
