module Ramaze
  module Helper
    # Helps display photographs
    module Photographs
      def description_of(photo)
        begin
          if exif = photo.exif
            description = ''
            description << photo.date.strftime('%m/%d/%Y') + ' '
#            description << exif.make if exif.make
            description << ' ' + exif.model + ', ' if exif.model
            description << ' ' + exif.focal_length_in_35mm_film.to_i.to_s + 'mm' if exif.focal_length_in_35mm_film
            description << ' at ' + neat_time(exif.exposure_time) if exif.exposure_time
            description << ' F' + exif.f_number.to_f.to_s if exif.f_number
          else
            nil
          end
        rescue
          # File might not be available, or EXIF might be missing... 
          return description
        end
      end

      # 1/60 => '1/60th'
      def neat_time(rational)
        if rational.denominator == 1
          rational.numerator.ordinal.to_s
        else
          "#{rational.numerator}/#{rational.denominator.ordinal.to_s}"
        end
      end
    end
  end
end
