/**
 * jquery.autotags.js - awesome tag editing
 *
 * Copyright (c) 2009 Kyle Kingsbury (aphyr@aphyr.com)
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 * 
 */

(function($) {
  $.fn.autotags = function(settings) {
    // Configuration
    var config = {
      cacheLength: 50
    };
    var keys = {
      backspace: 8,
      tab: 9,
      "return": 13,
      "escape": 27,
      comma: 188
    };

    if (settings) { $.extend(config, settings); }

    return this.each(function () {
      // MEAT AND POTATOES AND FUNCTIONS (MINUS THE COMESTIBLES)

      // Adds a string to the tag list.
      function addTag(tag) {
        var node = document.createElement("li");
        $(node).append('<span>' + tag + '</span><a href="#" title="Remove tag">x</a>');

        // When clicked, remove the node and save the tags list.
        $(node).find('a').click(function() {
          $(node).remove();
          saveTags();
        });

        // Add to the list.
        $list.append(node);
      }

      // Writes the tag list to the original input field.
      function saveTags() {
        $field.val(
          $.map($list.find('li > span'), function(obj) {
            return $(obj).text();
          }).join(',')
        );
      } 


      // ZOOM ZOOM ZOOM SET UP THE APP!
      // FILL THE DOM WITH USELESS CRAP!

      // Get original field
      var $field = $(this);

      // Hide field and append our widget
      $field.hide();
      var $container = $field.after('<div class="tag-editor"></div>').next();

      // Tag list
      $container.append('<ul></ul>');
      var $list = $container.find('ul');

      // Input field
      $container.append('<input type="text">');
      var $input = $container.find('input');

      // Visual clear
      $container.after('<div style="clear: both"></div>');

      // Add tags from the original field's contents.
      if ($.trim($field.val()) !== '') {
        $.each($field.val().split(','), function(i, tag) { 
          addTag($.trim(tag));
        });
        saveTags();
      }

      // Add autocomplete functionality!
      $input.autocomplete(config.url);

      
      // IM CALLING SEXY BACK(YEAH);
      // THOSE OTHER FUNCTIONS DON'T KNOW HOW TO ACT;
      
      // Focus input field when any part of the editor is clicked.
      $container.click(function() {
        $input.focus();
      });

      // Handle keypresses in the input box...
      $input.keydown(function(e, code) {
        code = code || e.keyCode;
        if (code == keys['return'] || code == 188 || code == keys.tab) {
          if ($input.val() !== '') {
            // Accept new tag
            var newTag = $input.val();
            $input.val('');
            addTag(newTag);
            saveTags();

            // Don't submit/leave/add a comma!
            return false;
          }
        } else if (code == keys.backspace && $input.val() === '') {
          // Remove the previous tag
          $list.find("li:last").remove();
          saveTags();
        }
      });
    });
  };

  // Private methods
})(jQuery);
