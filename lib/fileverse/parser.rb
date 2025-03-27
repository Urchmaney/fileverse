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
        @snapshots = []
      end

      def parse
        verify_first_header
        parse_header_lines
      end

      def snapshot_count
        @snapshots.length
      end

      private

      def verify_first_header
        first_line = @iterator.next
        /\A<\#{6}(?<cursor>\d+)\z/ =~ first_line
        raise CorruptFormat unless cursor

        @cursor = cursor
      end

      def parse_header_lines
        loop do
          line = @iterator.next
          unless /\A[[:blank:]]*(?<start>\d+)[[:blank:]]*~>[[:blank:]]*(?<stop>\d+)[[:blank:]]*\z/ =~ line
            break if line == CLOSE_TAG

            raise CorruptFormat
          end
          raise CorruptFormat if stop.to_i < start.to_i || start.to_i < (@snapshots.last&.stop || 0)

          @snapshots.push Snapshot.new(start.to_i, stop.to_i)
        end
      end

      # Snapshot for each file
      class Snapshot
        attr_reader :start, :stop

        def initialize(start, stop)
          @start = start
          @stop = stop
        end
      end
    end
  end
end
