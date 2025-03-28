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

      attr_reader :path, :cursor, :line_index

      def initialize(path)
        @path = path
        @iterator = File.foreach(path, chomp: true)
        @line_index = 0
        @snapshots = []
      end

      def parse
        verify_first_header
        parse_header_lines
        parse_snapshots
      end

      def snapshot_count
        @snapshots.length
      end

      private

      def verify_first_header
        first_line = next_line
        /\A<\#{6}(?<cursor>\d+)\z/ =~ first_line
        raise CorruptFormat unless cursor

        @cursor = cursor
      end

      def parse_header_lines
        loop do
          line = next_line
          unless /\A[[:blank:]]*(?<start>\d+)[[:blank:]]*~>[[:blank:]]*(?<stop>\d+)[[:blank:]]*\z/ =~ line
            break if line == CLOSE_TAG

            raise CorruptFormat
          end
          raise CorruptFormat if stop.to_i < start.to_i

          @snapshots.push Snapshot.new(start.to_i, stop.to_i)
        end
      end

      def parse_snapshots
        @snapshots.each do |snap|
          raise CorruptFormat, " Wrong indexing in header." if line_index != snap.start

          snap.content = snap_content(snap)
        end

        raise CorruptFormat, " Content remains after parsing." unless peek_line.nil?
      end

      def snap_content(snap)
        result = []
        (snap.stop - snap.start).times { result.push next_line }
        result
      end

      def next_line
        @line_index += 1
        @iterator.next
      rescue StopIteration
        raise CorruptFormat, "Check the snapshots lengths with header config."
      end

      def peek_line
        @iterator.peek
      rescue StopIteration
        nil
      end

      # Snapshot for each file
      class Snapshot
        attr_reader :start, :stop
        attr_accessor :content

        def initialize(start, stop)
          @start = start
          @stop = stop
        end
      end
    end
  end
end
