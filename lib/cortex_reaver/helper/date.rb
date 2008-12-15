module Ramaze
  module Helper
    # Provides assistance methods for displaying dates of objects.
    module Date
      # Puts out a line describing the creation (and modification) date of a
      # model. If times are within identical_tolerance seconds (for example,
      # because you forgot something on the form, hit back, and updated the
      # record), the update time isn't displayed.
      def date_line(model, identical_tolerance = 3600)
        c = model.created_on
        u = model.updated_on
        date = '<span class="date">' + c.strftime('%A, %e %B %Y, %H:%M') + "</span>"

        if (u - c) > identical_tolerance
          # A significant modification time.
          if u.year != c.year
            date << " (updated <span class=\"date\">#{u.strftime('%A, %e %B %Y, %H:%M')}</span>)"
          elsif u.day != c.day
            date << " (updated <span class=\"date\">#{u.strftime('%A, %e %B, %H:%M')})</span>"
          else
            date << " (updated <span class=\"date\">#{u.strftime('%H:%M')}</span>)"
          end
        end

        date
      end
    end
  end
end
