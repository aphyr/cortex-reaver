module Ramaze
  module Helper
    module Canonical
      Helper::LOOKUP << self

      # Returns the canonical name for this model, given a candidate new name.
      def canonicalize
        respond self.class.const_get('MODEL').canonicalize(
          request[:new],
          :id => request[:id]
        )
      end

      private

      # Adds an AJAX-ified name field for a model.
      def live_name_field(model, opts={:name => 'name', :watch => 'title'})
        name = opts[:name]
        watch = opts[:watch]
        title = opts[:title] || name.to_s.titleize

        s = "<p><label for=\"#{name}\">#{title}</label>"
        s << "<input name=\"#{name}\" id=\"#{name}\" type=\"text\" value=\"#{attr_h(model.send(opts[:name]))}\" /></p>"

        s << <<EOF
<script type="text/javascript">
/* <![CDATA[ */

// Updates the "name" field as the watched field changes.
$('##{watch}').change(function () {
    $.get('#{rs('canonicalize')}', {
      "new": $('##{watch}').val(),
      "id": '#{model.id}'
    }, function(response) {
      $('##{name}').val(response);
    })
});

// Canonicalizes the name when we're done, just to make sure.
$('##{name}').blur(function() {
  $.get('#{rs('canonicalize')}', {
    "new": $('##{name}').val(),
    "id": '#{model.id}'
  }, function(response) {
    $('##{name}').val(response);
  })
});

/* ]]> */
</script>
EOF
      end
    end
  end
end
