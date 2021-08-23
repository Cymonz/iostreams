require_relative "test_helper"

class RowReaderTest < Minitest::Test
  describe IOStreams::Row::Reader do
    let :file_name do
      File.join(File.dirname(__FILE__), "files", "test.csv")
    end

    let :expected do
      CSV.read(file_name)
    end

    describe "#each" do
      it "file" do
        rows  = []
        count = IOStreams::Row::Reader.file(file_name) do |io|
          io.each { |row| rows << row }
        end
        assert_equal expected, rows
        assert_equal expected.size, count
      end

      it "with no block returns enumerator" do
        rows = IOStreams::Row::Reader.file(file_name) do |io|
          io.each.first(100)
        end
        assert_equal expected, rows
      end

      it "stream" do
        rows  = []
        count = IOStreams::Line::Reader.file(file_name) do |file|
          IOStreams::Row::Reader.stream(file) do |io|
            io.each { |row| rows << row }
          end
        end
        assert_equal expected, rows
        assert_equal expected.size, count
      end
    end
  end
end
