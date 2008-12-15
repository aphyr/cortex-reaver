module Ramaze
  module Helper
    # Helps with attachments. Requires CRUD.
    module Attachments
      Helper::LOOKUP << self

      # Deletes an attachment on a model identified by id.
      def delete_attachment(id, name)
        require_admin
        
        unless @model = model_class.get(id)
          flash[:error] = "No such #{model_class.to_s.downcase} (#{h id}) exists."
          redirect Rs()
        end

        unless attachment = @model.attachment(name)
          flash[:error] = "No such attachment (#{h name}) exists."
          redirect @model.url
        end

        begin
          attachment.delete
          flash[:notice] = "Deleted attachment #{h name}."
        rescue => e
          flash[:error] = "Couldn't delete attachment #{h name}: #{h e.message}."
        end

        redirect @model.url
      end

      private

      # Saves all attachments from a request which match form to model. Returns true if
      # all were successful. Returns an array of attachments which were added.
      def add_attachments(model, attachments)
        attachments.each do |key, file|
          puts "adding #{key}: #{file.inspect}"
          if tempfile = file[:tempfile] and filename = file[:filename] and not filename.blank?
            model.attachment(filename).file = tempfile
          end
        end
        attachments
      end

      # Renders an attachments form for a model. Shows current attachments,
      # provides links to edit/delete, and a multiple-upload box. Doesn't
      # include form tags.
      def attachment_form(model)
       s = "<div id=\"files\" class=\"files\">\n  <ul>\n    "
       model.attachments.each do |attachment|
         s << "<li><a href=\"#{attachment.public_path}\">#{attachment.name}</a> (#{A('delete', :href => Rs(:delete_attachment, model.name, attachment.name))})</li>\n"
       end
       s << "</ul>\n</div>\n\n"

       s << <<EOF
<script type="text/javascript">
  // The number of created attachments.
  var created_attachments = 0;
  // The number of existing attachments.
  var existing_attachments = 0;

  function add_attachment_field_to(element) {
    // The attachment id we'll be creating;
    var id = created_attachments++;
    existing_attachments++;

    // The paragraph which contains our file entry line.
    var p = document.createElement('p');

    // Label.
    var label = document.createElement('label');
    label.setAttribute('for', 'attachments_' + id);
    label.appendChild(document.createTextNode('Attach:'));
    p.appendChild(label);

    // File field.
    field = document.createElement('input');
    field.setAttribute('id', 'attachments_' + id);
    field.setAttribute('name', 'attachments[' + id + ']');
    field.setAttribute('size', '30');
    field.setAttribute('type', 'file');
    field.setAttribute('onchange', 'attachment_field_changed(this);');
    p.appendChild(field);

    // Remove button
    remove = document.createElement('input');
    remove.setAttribute('type', 'button');
    remove.setAttribute('value', 'Clear');
    remove.setAttribute('onclick', 'clear_attachment_field(this.previousSibling);');
    p.appendChild(remove);

    // Add paragraph to element.
    element.appendChild(p);
  }

  function attachment_field_changed(field) {
    if (field.value.length == 0) {
      remove_attachment_field(field);
    }
    if (field.value.length > 0) {
      add_attachment_field_to(field.parentNode.parentNode);
    }
  }

  function clear_attachment_field(field) {
    field.value = '';
    attachment_field_changed(field);
  }

  function remove_attachment_field(field) {
    if (existing_attachments > 1) {
      field.parentNode.parentNode.removeChild(field.parentNode);
      existing_attachments--;
    }
  }

  // Add the first attachment field.
  add_attachment_field_to(document.getElementById('files'));
</script>
EOF
      end 

      # An HTML table of all attachments on a model
      def attachment_list(model)
         s = '<div class="attachments">'
         s << '<h2>Files</h2>'
         s << '<table>'
         model.attachments.each do |attachment|
           s << "
<tr>
  <td><a href=\"#{attr_h attachment.public_path}\">#{h attachment.name}</a></td>
  <td class=\"date\">#{File.mtime(attachment.local_path).strftime('%A, %d %B %Y, %H:%M')}</td>
</tr>"
         end
         s << "</table>\n</div>"
      end
    end
  end
end
