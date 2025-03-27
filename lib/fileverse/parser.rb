# frozen_string_literal: true

module Fileverse
  module Parser
    # Header class to process header section
    class Header
      CLOSE_TAG = "######>"
      def self.inital_header
        <<~INITIAL_HEADER
          <######0
          #{CLOSE_TAG}
        INITIAL_HEADER
      end

      attr_reader :path, :cursor

      def initialize(path)
        @path = path
        @iterator = File.foreach(path, chomp: true)
      end

      def parse
        verify_first_header
        parse_header_lines
      end

      def verify_first_header
        first_line = @iterator.next
        /\A<\#{6}(?<cursor>\d+)\z/ =~ first_line
        raise CorruptFormat unless cursor

        @cursor = cursor
      end

      def parse_header_lines
        loop do
          line = @iterator.next
          break if line == CLOSE_TAG
        end
      end
    end
  end
end
