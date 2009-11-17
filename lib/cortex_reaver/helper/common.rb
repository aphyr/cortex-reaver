module Ramaze
  module Helper
    module Common
      def flashbox
        f = ''
        flash.each do |k, v|
          f << '<div class="flash ' + k.to_s + '">'
          f << '<div class="icon"></div>'
          f << '<div class="body">' + v.to_s + '</div>'
          f << '<div class="clear"></div>'
          f << '</div>'
        end
        f
      end
    end
  end
end
