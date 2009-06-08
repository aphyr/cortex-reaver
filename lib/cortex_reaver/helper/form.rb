module Ramaze
  module Helper
    # Helps make forms, especially by escaping.
    module Form

      # Displays errors on a record.
      def errors_on(model)
        unless model.errors.empty?
          s = "<div class=\"form-errors\">\n<h3>Errors</h3>\n<ul>\n"
          model.errors.each do |attribute, error|
            s << "<li>#{attribute} #{error}</li>\n"
          end
          s << "</ul></div>"
        end
      end

      # Makes a form for a model. Takes a model, form action, and an array of
      # fields, which are passed to form_p.
      def form_for(model, action, fields = [])
        if model.nil?
          raise ArgumentError.new("needs a model")
        elsif action.nil?
          raise ArgumentError.new("needs an action")
        end

        f = ''

        unless model.errors.empty?
          f << "<div class=\"form-errors\">\n"
          f << "<ul>\n"
          model.errors.each do |attribute, error|
            f << "<li>#{attribute} #{error}\n</li>"
          end
          f << "</ul>\n"
          f << "</div>\n"
        end

        f = "<form action=\"#{action}\" method=\"post\" class=\"edit-form\">"

        fields.each do |field|
          case field
          when Array
            f << form_p(field[0], ({:model => model}.merge!(field[1] || {})))
          else
            f << form_p(field, :model => model)
          end
        end

        f << form_submit("Submit #{model.class.to_s.demodulize.titleize}")
      end

      # Makes a paragraph for accessing an attribute. Escapes the default value.
      # Parameters:
      #   id => the HTML id/name of the form field.
      #   :type => the type of form field to generate (text, password, checkbox...)
      #   :description => The label for the field (inferred from id by default)
      #   :model => The model to query for fields
      #   :default => The default value for the field (inferred from model and id)
      #   :p_class => Class attached to the paragraph
      def form_p(id, params = {})
        type = params[:type]
        p_class = params[:p_class]
        description = params[:description] || id.to_s.titleize
        model = params[:model]
        default = params[:default]
        if model and not default and model.respond_to? id
          default = model.send(id)
        end

        unless type
          case default
          when true
            type = 'checkbox'
        when false
            type = 'checkbox'
          else
            type = 'text'
          end
        end

        f = "<p #{p_class.nil? ? '' : 'class="' + attr_h(p_class) + '"'}>"
        unless type == 'checkbox' or type == 'hidden'
          f << "<label for=\"#{id}\">#{description}</label>"
        end

        if type == 'textarea'
          f << '<br />'
        end

        case type
        when 'textarea'
          f << "<textarea name=\"#{id}\" id=\"#{id}\">#{Rack::Utils::escape_html default}</textarea>"
        when 'checkbox'
          f << "<input type=\"checkbox\" name=\"#{id}\" id=\"#{id}\" #{default ? 'checked="checked"' : ''} />"
        else
         f << "<input name=\"#{id}\" id=\"#{id}\" type=\"#{type}\" value=\"#{attr_h(default)}\" />"
        end

        if type == 'checkbox'
          f << "<label class=\"checkbox\" for=\"#{id}\">#{description}</label>"
        end

        f << "</p>\n"
      end

      def form_submit(value = "Submit")
        '<p><input name="submit" type="submit" value="' + attr_h(value) + '" /></p>'
      end

      # Escapes quotes for HTML attributes.
      def attr_h(string)
        h(string).gsub('"', '&quot;')
      end
    end
  end
end
