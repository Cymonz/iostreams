require "csv"
module IOStreams
  class Tabular
    module Utility
      # For parsing a single line of CSV at a time
      # 2 to 3 times better performance than CSV.parse_line and considerably less
      # garbage collection required.
      #
      # Note: Only used prior to Ruby 2.6
      class CSVRow < ::CSV
        UTF8_ENCODING = Encoding.find("UTF-8").freeze

        def initialize(encoding = UTF8_ENCODING)
          @io = StringIO.new("".force_encoding(encoding))
          super(@io, row_sep: "")
        end

        # Parse a single line of CSV data
        # Parameters
        #   line [String]
        #     A single line of CSV data without any line terminators
        def parse(line)
          return if IOStreams::Utils.blank?(line)
          return if @skip_lines&.match(line)

          in_extended_col = false
          csv             = []
          parts           = line.split(@col_sep, -1)
          csv << nil if parts.empty?

          # This loop is the hot path of csv parsing. Some things may be non-dry
          # for a reason. Make sure to benchmark when refactoring.
          parts.each do |part|
            if in_extended_col
              # If we are continuing a previous column
              if part[-1] == @quote_char && part.count(@quote_char).odd?
                # extended column ends
                csv.last << part[0..-2]
                raise MalformedCSVError, "Missing or stray quote in line #{lineno + 1}" if csv.last =~ @parsers[:stray_quote]

                csv.last.gsub!(@quote_char * 2, @quote_char)
                in_extended_col = false
              else
                csv.last << part
                csv.last << @col_sep
              end
            elsif part[0] == @quote_char
              # If we are starting a new quoted column
              if part[-1] != @quote_char || part.count(@quote_char).odd?
                # start an extended column
                csv << part[1..-1]
                csv.last << @col_sep
                in_extended_col = true
              else
                # regular quoted column
                csv << part[1..-2]
                raise MalformedCSVError, "Missing or stray quote in line #{lineno + 1}" if csv.last =~ @parsers[:stray_quote]

                csv.last.gsub!(@quote_char * 2, @quote_char)
              end
            elsif part =~ @parsers[:quote_or_nl]
              # Unquoted field with bad characters.
              if part =~ @parsers[:nl_or_lf]
                raise MalformedCSVError, "Unquoted fields do not allow \\r or \\n (line #{lineno + 1})."
              else
                raise MalformedCSVError, "Illegal quoting in line #{lineno + 1}."
              end
            else
              # Regular ole unquoted field.
              csv << (part.empty? ? nil : part)
            end
          end

          # Replace tacked on @col_sep with @row_sep if we are still in an extended
          # column.
          csv[-1][-1] = @row_sep if in_extended_col

          raise MalformedCSVError, "Unclosed quoted field on line #{lineno + 1}." if in_extended_col

          @lineno += 1

          # save fields unconverted fields, if needed...
          unconverted = csv.dup if @unconverted_fields

          # convert fields, if needed...
          csv         = convert_fields(csv) unless @use_headers || @converters.empty?
          # parse out header rows and handle CSV::Row conversions...
          csv         = parse_headers(csv) if @use_headers

          # inject unconverted fields and accessor, if requested...
          add_unconverted_fields(csv, unconverted) if @unconverted_fields && (!csv.respond_to? :unconverted_fields)

          csv
        end

        # Return the supplied array as a single line CSV string.
        def render(row)
          row.map(&@quote).join(@col_sep) + @row_sep # quote and separate
        end

        alias to_csv render
      end
    end
  end
end
