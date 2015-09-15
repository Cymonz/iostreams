require_relative 'test_helper'

module Streams
  describe IOStreams::Xlsx::Reader do
    XLSX_CONTENTS = [
      ["first column", "second column", "third column"],
      ["data 1",       "data 2",        "more data"],
    ]

    describe '.open' do
      let(:file_name) { File.join(File.dirname(__FILE__), 'files', 'spreadsheet.xlsx') }

      describe 'with a file path' do
        before do
          @file = File.open(file_name)
        end

        it 'returns the contents of the file' do
          rows = []
          IOStreams::Xlsx::Reader.open(@file) do |spreadsheet|
            spreadsheet.each_line { |row| rows << row }
          end
          assert_equal(XLSX_CONTENTS, rows)
        end
      end

      describe 'with a file stream' do

        it 'returns the contents of the file' do
          rows = []
          File.open(file_name) do |file|
            IOStreams::Xlsx::Reader.open(file) do |spreadsheet|
              spreadsheet.each_line { |row| rows << row }
            end
          end

          assert_equal(XLSX_CONTENTS, rows)
        end
      end
    end

  end
end
