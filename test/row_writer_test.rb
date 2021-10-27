require_relative "test_helper"
require "csv"

class RowWriterTest < Minitest::Test
  describe IOStreams::Row::Writer do
    let :csv_file_name do
      File.join(File.dirname(__FILE__), "files", "test.csv")
    end

    let :raw_csv_data do
      File.read(csv_file_name)
    end

    let :csv_rows do
      CSV.read(csv_file_name)
    end

    let :temp_file do
      Tempfile.new("iostreams")
    end

    let :file_name do
      temp_file.path
    end

    after do
      temp_file.delete
    end

    describe ".stream" do
      it "file" do
        result =
          IOStreams::Row::Writer.file(file_name) do |io|
            csv_rows.each { |array| io << array }
            53534
          end
        assert_equal 53534, result
        result = ::File.read(file_name)
        assert_equal raw_csv_data, result
      end

      it "streams" do
        io_string = StringIO.new
        result    =
          IOStreams::Line::Writer.stream(io_string) do |io|
            IOStreams::Row::Writer.stream(io) do |stream|
              csv_rows.each { |array| stream << array }
              53534
            end
          end
        assert_equal 53534, result
        assert_equal raw_csv_data, io_string.string
      end
    end
  end
end
