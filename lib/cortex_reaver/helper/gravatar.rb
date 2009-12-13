module Ramaze
  module Helper
    module Gravatar
      # Returns an IMG tag for a comment.
      def gravatar_img(o)
         email = o.creator.email rescue o.email || 'anonymous'
         "<img src=\"http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}?r=pg&s=60\" alt=\"#{email}\" title=\"#{email}\" />"
      end
    end
  end
end
