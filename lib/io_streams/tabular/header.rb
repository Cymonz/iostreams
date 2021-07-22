module IOStreams
  class Tabular
    # Process files / streams that start with a header.
    class Header
      # Column names that begin with this prefix have been rejected and should be ignored.
      IGNORE_PREFIX = "__rejected__".freeze

      attr_accessor :columns, :allowed_columns, :required_columns, :skip_unknown

      # Header
      #
      # Parameters
      #   columns [Array<String>]
      #     Columns in this header.
      #     Note:
      #       It is recommended to keep all columns as strings to avoid any issues when persistence
      #       with MongoDB when it converts symbol keys to strings.
      #
      #   allowed_columns [Array<String>]
      #     List of columns to allow.
      #     Default: nil ( Allow all columns )
      #     Note:
      #     * So that rejected columns can be identified in subsequent steps, they will be prefixed with `__rejected__`.
      #       For example, `Unknown Column` would be cleansed as `__rejected__Unknown Column`.
      #
      #   required_columns [Array<String>]
      #     List of columns that must be present, otherwise an Exception is raised.
      #
      #   skip_unknown [true|false]
      #     true:
      #       Skip columns not present in the whitelist by cleansing them to nil.
      #       #as_hash will skip these additional columns entirely as if they were not in the file at all.
      #     false:
      #       Raises Tabular::InvalidHeader when a column is supplied that is not in the whitelist.
      def initialize(columns: nil, allowed_columns: nil, required_columns: nil, skip_unknown: true)
        @columns          = columns
        @required_columns = required_columns
        @allowed_columns  = allowed_columns
        @skip_unknown     = skip_unknown
      end

      # Returns [Array<String>] list columns that were ignored during cleansing.
      #
      # Each column is cleansed as follows:
      # - Leading and trailing whitespace is stripped.
      # - All characters converted to lower case.
      # - Spaces and '-' are converted to '_'.
      # - All characters except for letters, digits, and '_' are stripped.
      #
      # Notes:
      # * So that rejected columns can be identified in subsequent steps, they will be prefixed with `__rejected__`.
      #   For example, `Unknown Column` would be cleansed as `__rejected__Unknown Column`.
      # * Raises Tabular::InvalidHeader when there are no rejected columns left after cleansing.
      def cleanse!
        return [] if columns.nil? || columns.empty?

        ignored_columns = []
        self.columns    = columns.collect do |column|
          cleansed = cleanse_column(column)
          if allowed_columns.nil? || allowed_columns.include?(cleansed)
            cleansed
          else
            ignored_columns << column
            "#{IGNORE_PREFIX}#{column}"
          end
        end

        if !skip_unknown && !ignored_columns.empty?
          raise(IOStreams::Errors::InvalidHeader, "Unknown columns after cleansing: #{ignored_columns.join(',')}")
        end

        if ignored_columns.size == columns.size
          raise(IOStreams::Errors::InvalidHeader, "All columns are unknown after cleansing: #{ignored_columns.join(',')}")
        end

        if required_columns
          missing_columns = required_columns - columns
          unless missing_columns.empty?
            raise(IOStreams::Errors::InvalidHeader, "Missing columns after cleansing: #{missing_columns.join(',')}")
          end
        end

        ignored_columns
      end

      # Marshal to Hash from Array or Hash by applying this header
      #
      # Parameters:
      #   cleanse [true|false]
      #     Whether to cleanse and narrow the supplied hash to just those columns in this header.
      #     Only Applies to when the hash is already a Hash.
      #     Useful to turn off narrowing when the input data is already trusted.
      def to_hash(row, cleanse = true)
        return if IOStreams::Utils.blank?(row)

        case row
        when Array
          unless columns
            raise(IOStreams::Errors::InvalidHeader, "Missing mandatory header when trying to convert a row into a hash")
          end

          array_to_hash(row)
        when Hash
          cleanse && columns ? cleanse_hash(row) : row
        else
          raise(IOStreams::Errors::TypeMismatch, "Don't know how to convert #{row.class.name} to a Hash")
        end
      end

      def to_array(row, cleanse = true)
        if row.is_a?(Hash) && columns
          row = cleanse_hash(row) if cleanse
          row = columns.collect { |column| row[column] }
        end

        unless row.is_a?(Array)
          raise(
            IOStreams::Errors::TypeMismatch,
            "Don't know how to convert #{row.class.name} to an Array without the header columns being set."
          )
        end

        row
      end

      private

      def array_to_hash(row)
        h = {}
        columns.each_with_index { |col, i| h[col] = row[i] unless IOStreams::Utils.blank?(col) || col.start_with?(IGNORE_PREFIX) }
        h
      end

      # Perform cleansing on returned Hash keys during the narrowing process.
      # For example, avoids issues with case etc.
      def cleanse_hash(hash)
        unmatched = columns - hash.keys
        unless unmatched.empty?
          hash = hash.dup
          unmatched.each { |name| hash[cleanse_column(name)] = hash.delete(name) }
        end
        hash.slice(*columns)
      end

      def cleanse_column(name)
        cleansed = name.to_s.strip.downcase
        cleansed.gsub!(/\s+/, "_")
        cleansed.gsub!(/-+/, "_")
        cleansed.gsub!(/\W+/, "")
        cleansed
      end
    end
  end
end
