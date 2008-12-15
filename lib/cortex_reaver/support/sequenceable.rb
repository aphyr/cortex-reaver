module CortexReaver
  module Model
    # Sequences are models that have order. This module provides class
    # and instance methods that support sequential behavior like pagination, finding
    # the next or previoud record, and finding a "window" of results around a 
    # specific record.

    module Sequenceable

      # Which column table to order this sequence by
      DEFAULT_SEQUENCE_ORDER = :created_on
      DEFAULT_SEQUENCE_REVERSE = false
      DEFAULT_WINDOW_SIZE = 16

      # Class methods
      def self.included(base)
        base.instance_eval do
          attr_writer :sequence_order, :sequence_reverse, :window_size
          
          # Returns the sequence dataset (optionally, restricted to dataset)
          def sequence(dataset = self.dataset)
            if sequence_reverse
              dataset.reverse_order(sequence_order)
            else
              dataset.order(sequence_order)
            end
          end

          # Returns the first record in the sequence
          def first
            sequence.first
          end

          # Returns the last record in the sequence
          def last
            sequence.last
          end

          # Returns the table column to order by 
          def sequence_order
            @sequence_order || DEFAULT_SEQUENCE_ORDER
          end

          # Sets the table column to order by 
          def sequence_order=(order)
            @sequence_order = order
          end

          # Returns whether or not to reverse the order
          def sequence_reverse
            @sequence_reverse || DEFAULT_SEQUENCE_REVERSE
          end

          # Sets whether to reverse the sequence
          def sequence_reverse=(reverse)
            @sequence_reverse = reverse
          end

          # Returns an absolute window into this sequence, specified as an offset in 
          # window-sized increments from the beginning of the sequence. Hence 
          # window(0, 10) returns the first ten records in the sequence, window(1, 10)
          # the next ten, and so on.
          #
          # One can also specify the special page_offsets :first or :last, which
          # return the first and last available windows.
          def window(page_offset, size = self.window_size)
            case page_offset
              when :first
                page_offset = 0
              when :last
                page_offset = window_count(size) - 1
              else
                page_offset = page_offset.to_i
            end

            # Don't ask for negative pages!
            page_offset = 0 if page_offset < 0

            # Calculate offset
            offset = page_offset * size

            # Limit dataset
            sequence.limit size, offset
          end

          # Returns the number of windows required to span this sequence
          def window_count(size = self.window_size)
            (Float(sequence.count) / size).ceil
          end

          # Returns the size of a window into this sequence
          def window_size
            @window_size || DEFAULT_WINDOW_SIZE
          end

          # Sets the size of a window into this sequence
          def window_size=(size)
            @window_size = size
          end
        end
      end

      # Instance methods

      # Convenience references to class methods
      def sequence
        self.class.sequence
      end

      def sequence_order
        self.class.sequence_order
      end

      def sequence_reverse
        self.class.sequence_reverse
      end

      # Returns the next record in the sequence. Caches--use next(true) to refresh.
      def next(refresh_cache = false)
        if refresh_cache
          @next = sequence.filter(sequence_order > send(sequence_order)).limit(1).first
        else
          @next ||= sequence.filter(sequence_order > send(sequence_order)).limit(1).first
        end
      end

      # Returns true if a next record exists. Caches--use next(true) to refresh.
      def next?(refresh_cache = false)
        if refresh_cache
          @next_exists ||= self.next_count > 0 ? true : false
        else
          @next_exists = self.next_count > 0 ? true : false
        end
      end
     
      # Returns the number of succeeding records
      def next_count
        sequence.filter(sequence_order > send(sequence_order)).count
      end

      # Returns the previous record in the sequence. Caches--use previous(true) to
      # refresh.
      def previous(refresh_cache = false)
        if refresh_cache
          @previous = sequence.filter(sequence_order < send(sequence_order)).reverse.limit(1).first
        else
          @previous ||= sequence.filter(sequence_order < send(sequence_order)).reverse.limit(1).first
        end 
      end

      # Returns true if a previous record exists. Caches--use previous?(true) to
      # refresh.
      def previous?(refresh_cache = false)
        if refresh_cache
          @previous_exists = self.previous_count > 0 ? true : false
        else
          @previous_exists ||= self.previous_count > 0 ? true : false
        end
      end

      # Returns the number of preceding records
      def previous_count
        sequence.filter(sequence_order < send(sequence_order)).count
      end

      alias :position :previous_count

      # Returns a collection of records around this record.
      # Mode is one of:
      # 1. :absolute Returns a window containing this record in even multiples from
      #              the first record, like a page of a book.
      # 2. :float    Returns a centered window of the provided size. If the edge of
      #              the sequence is reached, the window shifts to include more
      #              elements of the sequence. If no more elements are available 
      #              (the window is larger than the size of the sequence), the 
      #              entire sequence is returned. If the size is even, one more
      #              record is returned suceeding this record than preceding this
      #              record, if possible.
      # 3. :clip     Returns a centered window of or smaller than the given size. If
      #              the edge of the sequence is reached, the window is clipped.
      def window(mode = :absolute, size = self.class.window_size)
        case mode
          when :absolute
            # Calculate page offset
            offset = (Float(position) / size).floor * size

            # Find records
            sequence.limit(size, offset)
          when :float
            count = sequence.count			# Total records
            if size >= count
              # Window includes all records in the sequence
              return self.class.find(:all)
            else
              # Window is smaller than the sequence
              position = self.position			              # This record's position
              previous_size = (Float(size - 1) / 2).floor	# How many records before
              next_size = (Float(size - 1) / 2).ceil		  # How many records after

              # Shift window if necessary
              if (displacement = previous_size - position) > 0
                # The window extends before the start of the sequence
                previous_size -= displacement
              elsif (displacement = next_size - self.next_count) > 0
                # The window extends beyond the end of the sequence
                previous_size += displacement
              end

              # Calculate window offset
              offset = position - previous_size

              # Find records
              sequence.limit(size, offset)
            end
          when :clip
            position = self.position                    # Our position in sequence
            previous_size = (Float(size - 1) / 2).floor # How many records before

            if (displacement = previous_size - position) > 0
              # The window extends before the beginning of the sequence
              size -= displacement
              offset = 0
            else
              # The window doesn't extend before the beginning of the sequence.
              offset = position - previous_size
            end

            # Find records.
            sequence.limit(size, offset)
          else
            raise ArgumentError.new('first argument must be one of :absolute, :float, :clip')
        end
      end

      # Returns a url for this record, viewed in an absolute window. TODO: handle non-default window sizes.
      def absolute_window_url(size = self.class.window_size)
        page = (Float(position) / size).floor
        self.class.url + '/page/' + page.to_s + '#' + self.class.to_s.underscore + 
          '_' + send(self.class.canonical_name_attr)
      end

      # Returns the absolute window index that this record appears in
      def absolute_window_index(size = self.class.window_size)
        (Float(self.position) / size).floor
      end
    end
  end
end
