module Ramaze
  module Helper
    # Simple render_template method
    module Template
#      # HACK: find the template to render 
#      def render_template(path)
#        opts = Ramaze::App[:cortex_reaver].options
#
#        # Construct possible directories
#        roots = opts.roots.map do |root| 
#          opts.views.map do |view| 
#            root = File.join(root, view)
#
#            if path[0..0] != '/'
#              # Append controller map as well
#              File.join(root, Ramaze::Current.action.node.mapping)
#            else
#              root
#            end
#          end
#        end
#        roots.flatten!
#
#        # Try to find the path in each root
#        roots.each do |root|
#          file = File.join(root, path)
#          if File.exists? file
#            return render_file(file)
#          end
#        end
#      
#        # Lookup failed    
#        raise RuntimeError.new("No template #{path} in any of #{roots.inspect}")
#      end
    end
  end
end
